from datetime import date
from sqlalchemy import desc, func
from extensions import db
from meal.models import MealEntry, Meal
from exercise.models import ExerciseLog, ExerciseType
from food.models import FoodItem

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