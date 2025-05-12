from datetime import date, datetime
from sqlalchemy import desc, func
from extensions import db
from meal.models import MealEntry, Meal
from exercise.models import ExerciseLog, ExerciseType
from food.models import FoodItem
from water.models  import  WaterLog

def get_recent_logs_for_user(user_id,  target_date):
   # Meal entries của target_date
    recent_meal = (
        db.session.query(MealEntry, Meal, FoodItem)
        .join(Meal, MealEntry.meal_id == Meal.meal_id)
        .join(FoodItem, MealEntry.food_item_id == FoodItem.food_item_id)
        .filter(
            Meal.user_id == user_id,
            func.date(MealEntry.created_at) == target_date
        )
        .order_by(desc(MealEntry.created_at))
        .limit(3)
        .all()
    )
   
     # Exercise logs của target_date
    recent_exercises = (
        db.session.query(ExerciseLog, ExerciseType)
        .join(ExerciseType, ExerciseLog.exercise_type_id == ExerciseType.exercise_type_id)
        .filter(
            ExerciseLog.user_id == user_id,
            func.date(ExerciseLog.logged_at) == target_date
        )
        .order_by(desc(ExerciseLog.logged_at))
        .limit(2)
        .all()
    )

    # In debug
    print(f"[DEBUG] Meals on {target_date}: {len(recent_meal)} entries")
    print(f"[DEBUG] Exercises on {target_date}: {len(recent_exercises)} entries")
    # Format dữ liệu trả về

    meals_data = [
        {
            "type": "meal",
            "name": food.name,
            "image_url": food.image_url,
            # calories trên 1 đơn vị (serving_size)
            "per_calories": float(food.calories),
            # số lượng user đã ăn
            "quantity": float(entry.quantity),
            "unit": entry.unit,
            # tổng calories thực sự ăn = entry.calories
            "calories": float(entry.calories),
            "protein": float(entry.protein_g),
            "carbs": float(entry.carbs_g),
            "fat": float(entry.fat_g),
            "created_at": entry.created_at.isoformat(),
        }
        for entry, meal, food in recent_meal
    ]

    exercises_data = [
        {
            "type": "exercise",
            "name": exercise_type.name,
            "category": exercise_type.category,
            "duration_min": log.duration_min,
            "calories_burned": float(log.calories_burned),
            "created_at": log.logged_at.isoformat(),
        }
        for log, exercise_type in recent_exercises
    ]

    print("[DEBUG] Merged logs:", meals_data + exercises_data)
    return meals_data + exercises_data


def get_aggregated_logs(user_id: int, query_date: date) -> list[dict]:
    """
    Lấy tất cả meal_entries, water_log, exercise_log của user trong ngày query_date,
    trả về list các dict đã gom chung và sắp theo timestamp.
    """
    start = datetime.combine(query_date, datetime.min.time())
    end = datetime.combine(query_date, datetime.max.time())

    # Meal entries
    meal_results = (
        db.session.query(MealEntry, FoodItem)
        .join(Meal, MealEntry.meal_id == Meal.meal_id)
        .join(FoodItem, MealEntry.food_item_id == FoodItem.food_item_id)
        .filter(Meal.user_id == user_id, Meal.meal_date == query_date,)
    .all()
)
    # Water logs
    waters = (
        WaterLog.query
        .filter(
            WaterLog.user_id == user_id,
            WaterLog.logged_at >= start,
            WaterLog.logged_at <= end,
        )
        .all()
    )

    # Exercise logs
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

    # Map meal entries
    for entry, food in meal_results:
        logs.append({
            'type': 'meal',
            'timestamp': entry.created_at.isoformat(),
            'data': {
                'entry_id': entry.entry_id,
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
    # Map water logs
    for w in waters:
        logs.append({
            'type': 'water',
            'timestamp': w.logged_at.isoformat(),
            'data': {
                'water_id': w.water_id,
                'intake_ml': w.intake_ml,
            }
        })

    # Map exercise logs
    for log, ex_type in exercises:
        logs.append({
            'type': 'exercise',
            'timestamp': log.logged_at.isoformat(),
            'data': {
                'name': ex_type.name,                 # thêm tên bài tập
                'duration_min': log.duration_min,
                'calories_burned': float(log.calories_burned),
            }
        })
    # Sắp xếp theo timestamp tăng dần
    logs.sort(key=lambda x: x['timestamp'])
    return logs