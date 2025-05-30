from extensions import db

class FoodItem(db.Model):
    __tablename__ = 'food_items'
    food_item_id = db.Column(db.BigInteger, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    name_unsigned = db.Column(db.String(255))
    brand = db.Column(db.String(255))
    serving_size = db.Column(db.Numeric(8, 2), nullable=False)  
    serving_unit = db.Column(db.String(50), nullable=False)
    calories = db.Column(db.Numeric(8, 2), nullable=False)
    protein_g = db.Column(db.Numeric(8, 2), nullable=False)
    carbs_g = db.Column(db.Numeric(8, 2), nullable=False)
    fat_g = db.Column(db.Numeric(8, 2), nullable=False)
    barcode = db.Column(db.String(50), unique=True)
    is_custom = db.Column(db.Boolean, nullable=False, default=False)
    created_by = db.Column(db.BigInteger, db.ForeignKey('users.user_id'))
    image_url = db.Column(db.Text)
    created_at = db.Column(db.DateTime(timezone=True), server_default=db.func.now())
    updated_at = db.Column(db.DateTime(timezone=True), server_default=db.func.now(), onupdate=db.func.now())

class BarcodeScan(db.Model):
    __tablename__ = 'barcode_scans'
    scan_id = db.Column(db.BigInteger, primary_key=True)
    user_id = db.Column(db.BigInteger, db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    barcode = db.Column(db.String(50), nullable=False)
    food_item_id = db.Column(db.BigInteger, db.ForeignKey('food_items.food_item_id'))
    scanned_at = db.Column(db.DateTime(timezone=True), server_default=db.func.now())


class FoodItemIngredient(db.Model):
    __tablename__ = 'food_item_ingredients'
    id = db.Column(db.BigInteger, primary_key=True)
    recipe_id = db.Column(db.BigInteger, db.ForeignKey('food_items.food_item_id'), nullable=False)
    ingredient_id = db.Column(db.BigInteger, db.ForeignKey('food_items.food_item_id'), nullable=False)
    quantity = db.Column(db.Numeric(8, 2), nullable=False)
    unit = db.Column(db.String(20), nullable=False, default='g')
