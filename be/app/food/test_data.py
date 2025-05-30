import sys
import os
import pandas as pd

# Cho phép import từ thư mục cha
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app import create_app
from extensions import db
from food.models import FoodItem

def clean_value(v):
    return float(v) if pd.notna(v) else 0.0

def import_foods():
    df = pd.read_excel("food_nutrients_with_unsigned.xlsx")
    df_with_image = df[df['image_url'].notna()]

    app = create_app()
    with app.app_context():
        for _, row in df_with_image.iterrows():
            item = FoodItem(
                name=row['name_vi'],
                name_unsigned=row['name_unsigned'],
                serving_size=clean_value(row['serving_size']),
                serving_unit=row['serving_unit'],
                calories=clean_value(row['calories']),
                protein_g=clean_value(row['protein_g']),
                fat_g=clean_value(row['fat_g']),
                carbs_g=clean_value(row['carbs_g']),
                image_url=row['image_url'],
                is_custom=False,
                created_by=None
            )
            db.session.add(item)
        db.session.commit()
        print(f"✅ Đã import {len(df_with_image)} món ăn có ảnh.")

if __name__ == "__main__":
    import_foods()
