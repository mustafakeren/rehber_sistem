from fastapi import FastAPI, File, UploadFile
from PIL import Image
import io

import numpy as np
from yolo_model import yolo_detect  # Doğru import işlemi

app = FastAPI()

@app.post("/upload-image/")
async def upload_image(file: UploadFile = File(...)):
    """
    Bir görsel dosyasını alır, YOLO modelini kullanarak nesne tespiti yapar ve sonucu döner.
    """
    try:
        # Dosyayı oku
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert("RGB")

        # Görseli numpy array formatına çevir
        frame = np.array(image)

        # YOLO ile nesne tespiti yap
        detected_object, confidence = yolo_detect(frame, target_object=None, confidence_threshold=0.7)

        return {
            "detected_objects": {
                "detected_object": detected_object,
                "confidence": confidence
            }
        }
    except Exception as e:
        return {"error": str(e)}
