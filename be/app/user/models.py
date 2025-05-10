from extensions import db

class User(db.Model):
    __tablename__ = 'users'
    user_id = db.Column(db.BigInteger, primary_key=True)
    provider = db.Column(db.String(20), nullable=False)
    provider_id = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(255), nullable=False, unique=True)
    display_name = db.Column(db.String(255))
    avatar_url = db.Column(db.Text)
    created_at = db.Column(db.DateTime(timezone=True), server_default=db.func.now())
    updated_at = db.Column(db.DateTime(timezone=True), server_default=db.func.now(), onupdate=db.func.now())


class UserProfile(db.Model):
    __tablename__ = 'user_profile'
    user_id = db.Column(db.BigInteger, db.ForeignKey('users.user_id', ondelete = 'CASCADE'), primary_key=True)
    first_name = db.Column(db.String(100))
    last_name = db.Column(db.String(100))
    date_of_birth = db.Column(db.Date)
    gender = db.Column(db.String(10))
    height_cm = db.Column(db.Numeric(5, 2))
    created_at = db.Column(db.DateTime(timezone=True), server_default=db.func.now())
    updated_at = db.Column(db.DateTime(timezone=True), server_default=db.func.now(), onupdate=db.func.now())


class UserSettings(db.Model):
    __tablename__ = 'user_settings'
    user_id                = db.Column(db.BigInteger, db.ForeignKey('users.user_id', ondelete='CASCADE'), primary_key=True)
    locale                 = db.Column(db.String(5), nullable=False, default='vi')
    timezone               = db.Column(db.String(50), nullable=False, default='Asia/Bangkok')
    weight_unit            = db.Column(db.String(2), nullable=False, default='kg')
    energy_unit            = db.Column(db.String(10), nullable=False, default='kcal')
    default_target_calories= db.Column(db.Integer)
    drink_water_reminder   = db.Column(db.Boolean, nullable=False, default=True)
    meal_reminder          = db.Column(db.Boolean, nullable=False, default=True)


class WeightLog(db.Model):
    __tablename__ = 'weight_log'
    weight_id = db.Column(db.BigInteger, primary_key=True)
    user_id = db.Column(db.BigInteger, db.ForeignKey('users.user_id', ondelete = 'CASCADE'), nullable=False)
    weight_kg = db.Column(db.Numeric(5, 2), nullable=False)
    logged_at = db.Column(db.DateTime(timezone=True), server_default=db.func.now())


class Goal(db.Model):
    __tablename__ = 'goals'
    goal_id = db.Column(db.BigInteger, primary_key=True)
    user_id = db.Column(db.BigInteger, db.ForeignKey('users.user_id', ondelete = 'CASCADE'), nullable=False)
    goal_type = db.Column(db.String(20), nullable=False) # weight
    target_value = db.Column(db.Numeric(10, 2), nullable=False)  # e.g., target weight in kg
    goal_direction = db.Column(db.String(20), nullable=False)  # 'gain' or 'lose'
    start_date = db.Column(db.DateTime(timezone=True), server_default=db.func.now())
    duration_weeks = db.Column(db.Integer, nullable=False)  # Duration in weeks
    weekly_rate = db.Column(db.Numeric(5, 2), nullable=False, default='0.75')  # e.g., 0.75 kg/week
    created_at = db.Column(db.DateTime(timezone=True), server_default=db.func.now())



