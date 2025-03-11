from ultralytics import YOLO

def yolo_detect(frame, target_object=None, confidence_threshold=0.7):
    """
    YOLO modelini kullanarak nesne tespiti yapar.
    - frame: Görsel numpy array formatında
    - target_object: İstenilen nesne türü (Ör. "chair", "table")
    - confidence_threshold: Doğruluk eşiği
    """
    model = YOLO("yolo11n.pt")  # YOLO model dosyasını yükle

    # YOLO ile tahmin yap
    results = model.predict(source=frame, show=False, save=False)

    detected_objects = []

    # Tespit edilen nesneleri işle
    for result in results:
        for box in result.boxes:
            cls = box.cls[0]  # Sınıf ID
            confidence = box.conf[0]  # Doğruluk oranı

            # Doğruluk eşiği ve istenen nesne kontrolü
            if confidence >= confidence_threshold and (target_object is None or model.names[int(cls)] == target_object):
                detected_objects.append({
                    "detected_object": model.names[int(cls)],
                    "confidence": confidence.item()  # Convert to a standard Python type
                })

    return detected_objects
