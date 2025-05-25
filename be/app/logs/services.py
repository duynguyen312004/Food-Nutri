from datetime import date, datetime, timedelta
from sqlalchemy import func
from sqlalchemy.orm import aliased
from extensions import db
from meal.models import MealEntry, Meal
from exercise.models import ExerciseLog, ExerciseType
from food.models import FoodItem
from water.models  import  WaterLog

def get_recent_logs_for_user(user_id, target_date):
    """
    Trả về danh sách các món ăn gần đây (tối đa 6), mỗi món là một food_item_id khác nhau,
    dựa trên bản ghi MealEntry gần nhất theo created_at.
    """
    start_date = target_date - timedelta(days=1)

    subquery = (
        db.session.query(
            MealEntry.food_item_id,
            func.max(MealEntry.created_at).label("latest_time")
        )
        .join(Meal, MealEntry.meal_id == Meal.meal_id)
        .filter(
            Meal.user_id == user_id,
            func.date(MealEntry.created_at) >= start_date,
            func.date(MealEntry.created_at) <= target_date,
        )
        .group_by(MealEntry.food_item_id)
        .subquery()
    )

    MealEntryAlias = aliased(MealEntry)

    recent_meal = (
        db.session.query(MealEntryAlias, Meal, FoodItem)
        .join(Meal, MealEntryAlias.meal_id == Meal.meal_id)
        .join(FoodItem, MealEntryAlias.food_item_id == FoodItem.food_item_id)
        .join(subquery, db.and_(
            MealEntryAlias.food_item_id == subquery.c.food_item_id,
            MealEntryAlias.created_at == subquery.c.latest_time
        ))
        .order_by(subquery.c.latest_time.desc())
        .limit(6)
        .all()
    )

    meals_data = [
        {
            "type": "meal",
            "food_item_id": food.food_item_id,
            "name": food.name,
            "image_url": food.image_url,
            "per_calories": float(food.calories),
            "quantity": float(entry.quantity),
            "unit": entry.unit,
            "calories": float(entry.calories),
            "protein": float(entry.protein_g),
            "carbs": float(entry.carbs_g),
            "fat": float(entry.fat_g),
            "serving_size": float(food.serving_size),
            "serving_unit": food.serving_unit,
            "created_at": entry.created_at.isoformat(),
        }
        for entry, meal, food in recent_meal
    ]

    return meals_data
def get_aggregated_logs(user_id: int, query_date: date) -> list[dict]:
    """Trả về tất cả log trong ngày cụ thể: món ăn, nước, bài tập. Dùng để hiển thị Timeline trong JournalPage."""
    start = datetime.combine(query_date, datetime.min.time())
    end = datetime.combine(query_date, datetime.max.time())

    meal_results = (
        db.session.query(MealEntry, FoodItem)
        .join(Meal, MealEntry.meal_id == Meal.meal_id)
        .join(FoodItem, MealEntry.food_item_id == FoodItem.food_item_id)
        .filter(Meal.user_id == user_id, Meal.meal_date == query_date,)
        .all()
    )

    waters = (
        WaterLog.query
        .filter(
            WaterLog.user_id == user_id,
            WaterLog.logged_at >= start,
            WaterLog.logged_at <= end,
        )
        .all()
    )

    exercises = (
        db.session.query(ExerciseLog, ExerciseType)
        .join(ExerciseType, ExerciseLog.exercise_type_id == ExerciseType.exercise_type_id)
        .filter(
            ExerciseLog.user_id == user_id,
            ExerciseLog.logged_at >= start,
            ExerciseLog.logged_at <= end,
        )
        .order_by(ExerciseLog.logged_at)
        .all()
    )

    logs: list[dict] = []

    for entry, food in meal_results:
        logs.append({
            'type': 'meal',
            'timestamp': entry.created_at.isoformat(),
            'logId': entry.entry_id, 
            'data': {
                'food_item_id': food.food_item_id,
                'name': food.name,
                'calories': float(entry.calories),
                'quantity': float(entry.quantity),
                'unit': entry.unit,
                'protein': float(entry.protein_g),
                'carbs': float(entry.carbs_g),
                'fat': float(entry.fat_g),
                'image_url': food.image_url,
            }
        })

    for w in waters:
        logs.append({
            'type': 'water',
            'timestamp': w.logged_at.isoformat(),
            'logId': w.water_id, 
            'data': {
                'intake_ml': w.intake_ml,
            }
        })

    for log, ex_type in exercises:
        logs.append({
            'type': 'exercise',
            'timestamp': log.logged_at.isoformat(),
            'logId': log.exercise_id,
            'data': {
                'name': ex_type.name,
                'duration_min': log.duration_min,
                'calories_burned': float(log.calories_burned),
            }
        })

    logs.sort(key=lambda x: x['timestamp'])
    return logs
    """"Dùng để ghi log mới khi người dùng thêm món ăn/nước/tập luyện. Được gọi từ /api/v1/logs với method POST, ứng với hành vi trong AddEntryPage."""
# Dùng để ghi log mới khi người dùng thêm món ăn/nước/tập luyện. Được gọi từ /api/v1/logs với method POST, ứng với hành vi trong AddEntryPage.

def create_water_log(user_id: int, timestamp, data: dict):
    log = WaterLog(
        user_id=user_id,
        intake_ml=data["intake_ml"],
        logged_at=timestamp,
    )
    db.session.add(log)

def create_meal_log(user_id: int, timestamp, data: dict):
    """
    Ghi log món ăn: tạo 1 bữa ăn (meal) và 1 entry trong bữa đó.
    Dữ liệu đầu vào:
    {
        "food_item_id": 123,
        "quantity": 150.0,
        "unit": "g",
        "calories": 320,
        "protein": 25.2,
        "carbs": 45.0,
        "fat": 11.0
    }
    """
    # Tạo meal đại diện (vì có thể sau này mở rộng thêm entry vào cùng meal)
    meal = Meal(
        user_id=user_id,
        name=data.get("meal_name", "Meal"),  # Optional name
        meal_date=timestamp.date(),
        created_at=timestamp,
    )
    db.session.add(meal)
    db.session.flush()  # để lấy meal_id

    # Tạo meal entry
    entry = MealEntry(
        meal_id=meal.meal_id,
        food_item_id=int(data["food_item_id"]),
        quantity=float(data["quantity"]),
        unit=data.get("unit", "g"),
        calories=float(data["calories"]),
        protein_g=float(data["protein"]),
        carbs_g=float(data["carbs"]),
        fat_g=float(data["fat"]),
        created_at=timestamp,
    )
    db.session.add(entry)


def create_exercise_log(user_id: int, timestamp, data: dict):
    log = ExerciseLog(
        user_id=user_id,
        exercise_type_id=data["exercise_type_id"],
        duration_min=data["duration_min"],
        logged_at=timestamp,
    )
    db.session.add(log)


# Xoá log tương ứng khi người dùng vuốt xoá trong JournalPage
def delete_meal_log(log_id: int, user_id: int):
    entry = (
        db.session.query(MealEntry)
        .join(Meal, MealEntry.meal_id == Meal.meal_id)
        .filter(MealEntry.entry_id == log_id, Meal.user_id == user_id)
        .first()
    )
    if entry:
        meal_id = entry.meal_id
        db.session.delete(entry)
        # kiểm tra nếu meal không còn entry nào thì xoá luôn
        remaining = MealEntry.query.filter_by(meal_id=meal_id).count()
        if remaining == 0:
            Meal.query.filter_by(meal_id=meal_id, user_id=user_id).delete()

def delete_water_log(log_id: int, user_id: int):
    log = WaterLog.query.filter_by(water_id=log_id, user_id=user_id).first()
    if log:
        db.session.delete(log)
def delete_exercise_log(log_id: int, user_id: int):
    log = (
        db.session.query(ExerciseLog)
        .filter(ExerciseLog.exercise_id == log_id, ExerciseLog.user_id == user_id)
        .first()
    )
    if log:
        db.session.delete(log)
#Chỉ cập nhật lượng (quantity) và tính lại calories/macros trong MealEntry khi người dùng chỉnh sửa log từ FoodDetailPage.
def update_meal_quantity(log_id: int, quantity: float, user_id: int):
    entry = (
        db.session.query(MealEntry)
        .join(Meal, MealEntry.meal_id == Meal.meal_id)
        .filter(MealEntry.entry_id == log_id, Meal.user_id == user_id)
        .first()
    )
    if entry:
        print("Before update:", entry.quantity, entry.calories)
        food = FoodItem.query.get(entry.food_item_id)
        factor = float(quantity) / float(food.serving_size)
        entry.quantity = quantity
        entry.calories = float(food.calories) * factor
        entry.protein_g = float(food.protein_g) * factor
        entry.carbs_g = float(food.carbs_g) * factor
        entry.fat_g = float(food.fat_g) * factor
        print("After update:", entry.quantity, entry.calories)