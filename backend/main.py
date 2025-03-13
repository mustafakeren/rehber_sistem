import os
import shutil
import cv2
import numpy as np
import io
from fastapi import FastAPI, File, UploadFile
from PIL import Image
from yolo_model import yolo_detect
import pytesseract

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
        os.makedirs(UPLOAD_FOLDER, exist_ok=True)
        clear_uploads_folder()

        # Dosyayı oku ve PIL formatına çevir
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert("RGB")

        # Görseli numpy array formatına çevir
        frame = np.array(image)
        frame = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)  # OpenCV formatına çevir

        # YOLO ile nesne tespiti yap
        detected_objects = yolo_detect(frame, confidence_threshold=0.5)

        # Get image dimensions
        image_height, image_width, _ = frame.shape

        return {
            "detected_objects": detected_objects,
            "image_width": image_width,
            "image_height": image_height
        }
    except Exception as e:
        return {"error": str(e)}

@app.post("/extract-text/")
async def extract_text(file: UploadFile = File(...)):
    """
    Bir görsel dosyasını alır ve Tesseract OCR ile metin çıkarır.
    """
    try:
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert("RGB")
        text = pytesseract.image_to_string(image, lang='tur')
        return {"text": text}
    except Exception as e:
        return {"error": str(e)}
