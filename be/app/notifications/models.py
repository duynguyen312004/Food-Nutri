from app.extensions import db

class NotificationSettings(db.Model):
    __tablename__ = 'notification_settings'
    notif_id = db.Column(db.BigInteger, primary_key=True)
    user_id = db.Column(db.BigInteger, db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    type = db.Column(db.String(30), nullable=False)  # e.g., 'meal_reminder', 'drink_water', etc.
    time_of_day = db.Column(db.Time, nullable=False)
    days_of_week = db.Column(db.ARRAY(db.SmallInteger), nullable=False)  # 0=Sunday ... 6=Saturday
    enabled = db.Column(db.Boolean, nullable=False, default=True)
    created_at = db.Column(db.DateTime(timezone=True), server_default=db.func.now())
