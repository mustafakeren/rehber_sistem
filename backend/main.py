import os
import shutil
from fastapi import FastAPI, File, UploadFile
from PIL import Image
import io
import numpy as np
from yolo_model import yolo_detect

app = FastAPI()

UPLOAD_FOLDER = "uploads/"

def clear_uploads_folder():
    for filename in os.listdir(UPLOAD_FOLDER):
        file_path = os.path.join(UPLOAD_FOLDER, filename)
        try:
            if os.path.isfile(file_path) or os.path.islink(file_path):
                os.unlink(file_path)
                print("Deleted", file_path)
            elif os.path.isdir(file_path):
                shutil.rmtree(file_path)
                print("Deleted directory", file_path)
        except Exception as e:
            print(f'Failed to delete {file_path}. Reason: {e}')

@app.post("/upload-image/")
async def upload_image(file: UploadFile = File(...)):
    """
    Bir görsel dosyasını alır, kaydeder ve YOLO ile analiz eder.
    """
    try:
        # Klasör yoksa oluştur
        os.makedirs(UPLOAD_FOLDER, exist_ok=True)

        # Klasörü temizle
        clear_uploads_folder()

        # Dosyayı oku
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert("RGB")

        # Dosyayı kaydet
        file_path = os.path.join(UPLOAD_FOLDER, file.filename)
        image.save(file_path)

        # Görseli numpy array formatına çevir
        frame = np.array(image)

        # YOLO ile nesne tespiti yap
        detected_objects = yolo_detect(frame, confidence_threshold=0.7)

        return {
            "detected_objects": detected_objects
        }
    except Exception as e:
        return {"error": str(e)}