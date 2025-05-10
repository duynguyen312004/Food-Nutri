from extensions import db

class ExerciseType(db.Model):
    __tablename__ = 'exercise_type'
    exercise_type_id = db.Column(db.BigInteger, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    mets = db.Column(db.Numeric(5, 2))
    category = db.Column(db.String(50))
    icon_url = db.Column(db.Text)

class ExerciseLog(db.Model):
    __tablename__ = 'exercise_log'
    exercise_id = db.Column(db.BigInteger, primary_key=True)
    user_id = db.Column(db.BigInteger, db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    exercise_type_id = db.Column(db.BigInteger, db.ForeignKey('exercise_type.exercise_type_id'), nullable=False)
    duration_min = db.Column(db.Integer, nullable=False)
    calories_burned = db.Column(db.Numeric(8, 2))
    logged_at = db.Column(db.DateTime(timezone=True), server_default=db.func.now())
    user = db.relationship('User', backref='exercise_logs')
    exercise_type = db.relationship('ExerciseType', backref='exercise_logs')
