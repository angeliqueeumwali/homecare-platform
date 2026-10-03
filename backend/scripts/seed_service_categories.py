"""Seed the service_categories table with default home-care services.

Safe to re-run: categories are matched by name, existing rows are updated
with the description/image_url rather than duplicated.

Usage:
    .venv/bin/python -m scripts.seed_service_categories
"""

import asyncio
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database.connection import SessionLocal
from app.models.service_category import ServiceCategory
from app.repositories.service_category_repository import ServiceCategoryRepository

STATIC_SERVICES = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "app",
    "static",
    "services",
)

IMAGE_EXTENSIONS = (".jpg", ".jpeg", ".png", ".webp", ".gif")


def resolve_image_url(slug):
    """Return the public URL for a category image, or None if no file exists.

    The image file itself is the source of truth: drop a new picture into
    app/static/services/<slug>.jpg (or .png/.webp) and re-run this script to
    point the category at it. No code change needed.
    """
    for ext in IMAGE_EXTENSIONS:
        if os.path.isfile(os.path.join(STATIC_SERVICES, f"{slug}{ext}")):
            return f"/static/services/{slug}{ext}"
    return None


CATEGORIES = [
    {
        "slug": "housekeeping",
        "name": "General Housekeeping",
        "description": "Routine cleaning of rooms, surfaces, floors and general tidying.",
    },
    {
        "slug": "laundry",
        "name": "Laundry Services",
        "description": "Washing, ironing, folding and collection or delivery of laundry.",
    },
    {
        "slug": "cooking",
        "name": "Cooking and Meal Preparation",
        "description": "Prepared meals, cooking support and nutrition-friendly menus.",
    },
    {
        "slug": "elderly-care",
        "name": "Elderly Care",
        "description": "Companionship, daily routines, mobility support and medication reminders.",
    },
    {
        "slug": "child-care",
        "name": "Child Care",
        "description": "Home-based childcare, homework help and after-school activities.",
    },
    {
        "slug": "pet-care",
        "name": "Pet Care",
        "description": "Feeding, walking, grooming assistance and general pet wellbeing.",
    },
    {
        "slug": "home-repair",
        "name": "Home Repairs and Maintenance",
        "description": "Small repairs, fixtures, plumbing touch-ups and maintenance checks.",
    },
    {
        "slug": "medical-nursing",
        "name": "Medical and Nursing",
        "description": "Qualified nursing support, wound care and health monitoring.",
    },
    {
        "slug": "companionship",
        "name": "Companionship",
        "description": "Social visits, conversation, errands and leisure activities.",
    },
    {
        "slug": "gardening",
        "name": "Gardening and Lawn Care",
        "description": "Lawn mowing, planting, pruning and general garden upkeep.",
    },
]


async def main():
    created, updated, missing = 0, 0, []
    async with SessionLocal() as db:
        for entry in CATEGORIES:
            image_url = resolve_image_url(entry["slug"])
            if image_url is None:
                missing.append(entry["slug"])

            existing = await ServiceCategoryRepository.get_by_name(db, entry["name"])
            if existing:
                existing.description = entry["description"]
                existing.image_url = image_url
                existing.is_active = True
                await ServiceCategoryRepository.update(db, existing)
                updated += 1
                print(f"updated  {entry['name']:32} {image_url or '(no image)'}")
            else:
                await ServiceCategoryRepository.create(
                    db,
                    ServiceCategory(
                        name=entry["name"],
                        description=entry["description"],
                        image_url=image_url,
                    ),
                )
                created += 1
                print(f"created  {entry['name']:32} {image_url or '(no image)'}")

    print(f"\nDone. {created} created, {updated} updated.")
    if missing:
        print(
            "No image file found for: "
            + ", ".join(missing)
            + f"\nAdd them to {STATIC_SERVICES} and re-run."
        )


if __name__ == "__main__":
    asyncio.run(main())
