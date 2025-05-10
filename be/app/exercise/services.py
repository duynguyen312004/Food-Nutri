from extensions import db
from exercise.models import ExerciseLog, ExerciseType

def fetch_exercise_types():
    """Trả về tất cả các loại bài tập."""
    return ExerciseType.query.order_by(ExerciseType.name).all()

def create_exercise_log(user_id: int, exercise_type_id: int, duration_min: int) -> ExerciseLog:
    """
    Tạo và lưu ExerciseLog. Trigger calculate_calories_burned
    sẽ tự động tính calories_burned dựa trên MET và weight_log gần nhất.
    """
    log = ExerciseLog(
        user_id=user_id,
        exercise_type_id=exercise_type_id,
        duration_min=duration_min
    )
    db.session.add(log)
    db.session.commit()        # trigger sẽ fill calories_burned trước khi commit
    db.session.refresh(log)
    return log