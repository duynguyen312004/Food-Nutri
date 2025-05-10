from extensions import db
from food.models import FoodItem

class Meal(db.Model):
    __tablename__ = 'meal'
    meal_id = db.Column(db.BigInteger, primary_key=True)
    user_id = db.Column(db.BigInteger, db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    meal_date = db.Column(db.Date, nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), server_default=db.func.now())

class MealEntry(db.Model):
    __tablename__ = 'meal_entries'
    entry_id = db.Column(db.BigInteger, primary_key=True)
    meal_id = db.Column(db.BigInteger, db.ForeignKey('meal.meal_id', ondelete='CASCADE'), nullable=False)
    food_item_id = db.Column(db.BigInteger, db.ForeignKey('food_items.food_item_id'), nullable=False)
    quantity = db.Column(db.Numeric(8, 2), nullable=False)
    unit = db.Column(db.String(50))
    calories = db.Column(db.Numeric(8, 2), nullable=False)
    protein_g = db.Column(db.Numeric(8, 2), nullable=False)
    carbs_g = db.Column(db.Numeric(8, 2), nullable=False)
    fat_g = db.Column(db.Numeric(8, 2), nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), server_default=db.func.now())
