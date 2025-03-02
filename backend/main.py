import os
from fastapi import FastAPI, File, UploadFile
from PIL import Image
import io
import numpy as np
import shutil
from yolo_model import yolo_detect

app = FastAPI()

UPLOAD_FOLDER = "uploads/"  # Fotoğrafların kaydedileceği klasör

@app.post("/upload-image/")
async def upload_image(file: UploadFile = File(...)):
    """
    Bir görsel dosyasini alir, kaydeder ve YOLO ile analiz eder.
    """
    try:
        # Klasör yoksa oluştur
        os.makedirs(UPLOAD_FOLDER, exist_ok=True)

        # Dosyayı oku
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert("RGB")

        # Dosyayı kaydet
        file_path = f"{UPLOAD_FOLDER}{file.filename}"
        image.save(file_path)

        # Görseli numpy array formatına çevir
        frame = np.array(image)

        # YOLO ile nesne tespiti yap
        detected_object, confidence = yolo_detect(frame, confidence_threshold=0.7)

        return {
            "detected_objects": {
                "detected_object": detected_object,
                "confidence": confidence
            }
        }
    except Exception as e:
        return {"error": str(e)}
