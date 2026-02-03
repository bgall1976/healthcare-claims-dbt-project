#!/usr/bin/env python3
"""
Generate Synthetic Healthcare Claims Data

This script generates realistic synthetic healthcare data for the dbt project.
All data is completely synthetic and does not represent real patients or providers.

Usage:
    python generate_synthetic_data.py --output-dir ../seeds --num-patients 100

Dependencies:
    pip install faker pandas numpy
"""

import argparse
import random
from datetime import datetime, timedelta
from pathlib import Path

import pandas as pd
from faker import Faker

fake = Faker()
Faker.seed(42)
random.seed(42)

# Reference data
SPECIALTIES = [
    ("Internal Medicine", "Primary Care"),
    ("Family Medicine", "Primary Care"),
    ("Cardiology", "Medical Specialty"),
    ("Neurology", "Medical Specialty"),
    ("Gastroenterology", "Medical Specialty"),
    ("Pulmonology", "Medical Specialty"),
    ("Orthopedics", "Surgical Specialty"),
    ("Psychiatry", "Behavioral Health"),
    ("Dermatology", "Other Specialty"),
]

PLAN_TYPES = ["HMO", "PPO", "EPO", "POS"]

PLAN_NAMES = [
    "Blue Cross HMO",
    "Blue Cross PPO",
    "Aetna PPO",
    "Aetna HMO",
    "United HMO",
    "United EPO",
    "Cigna EPO",
    "Cigna PPO",
    "Harvard Pilgrim HMO",
    "Tufts HMO",
]

ICD10_CODES = [
    ("E11.9", "Type 2 diabetes mellitus without complications", "Diabetes", True),
    ("I10", "Essential (primary) hypertension", "Hypertension", True),
    ("J06.9", "Acute upper respiratory infection", "Respiratory Infection", False),
    ("M54.5", "Low back pain", "Musculoskeletal", False),
    ("F32.9", "Major depressive disorder", "Depression", True),
    ("K21.0", "Gastro-esophageal reflux disease", "GERD", True),
    ("N39.0", "Urinary tract infection", "UTI", False),
    ("G43.909", "Migraine unspecified", "Migraine", True),
    ("L30.9", "Dermatitis unspecified", "Dermatitis", False),
    ("J45.909", "Unspecified asthma", "Asthma", True),
]

CPT_CODES = [
    ("99212", "Office visit level 2", "E&M", False, 100),
    ("99213", "Office visit level 3", "E&M", False, 150),
    ("99214", "Office visit level 4", "E&M", False, 200),
    ("99215", "Office visit level 5", "E&M", False, 250),
    ("82947", "Glucose blood test", "Lab", False, 45),
    ("83036", "Hemoglobin A1c", "Lab", False, 85),
    ("93000", "Electrocardiogram", "Cardiology", False, 75),
    ("80053", "Comprehensive metabolic panel", "Lab", False, 120),
    ("71046", "Chest X-ray 2 views", "Radiology", False, 350),
    ("72148", "MRI lumbar spine", "Radiology", False, 1200),
    ("43239", "Upper GI endoscopy", "Surgery", True, 2500),
]

MA_CITIES = [
    ("Boston", "02101"),
    ("Cambridge", "02139"),
    ("Worcester", "01601"),
    ("Springfield", "01103"),
    ("Lowell", "01852"),
    ("Quincy", "02169"),
    ("Somerville", "02143"),
    ("Newton", "02458"),
    ("Brookline", "02445"),
    ("Medford", "02155"),
]


def generate_npi():
    """Generate a valid-looking NPI (10 digits)."""
    return "".join([str(random.randint(0, 9)) for _ in range(10)])


def generate_patients(num_patients: int) -> pd.DataFrame:
    """Generate synthetic patient data."""
    patients = []
    
    for i in range(num_patients):
        patient_id = f"P{str(i+1).zfill(3)}"
        city, zip_code = random.choice(MA_CITIES)
        plan_type = random.choice(PLAN_TYPES)
        
        patient = {
            "patient_id": patient_id,
            "first_name": fake.first_name(),
            "last_name": fake.last_name(),
            "date_of_birth": fake.date_of_birth(minimum_age=5, maximum_age=85),
            "gender": random.choice(["M", "F"]),
            "address_line_1": fake.street_address(),
            "city": city,
            "state": "MA",
            "zip_code": zip_code,
            "plan_type": plan_type,
            "plan_name": random.choice([p for p in PLAN_NAMES if plan_type in p] or PLAN_NAMES),
            "member_id": f"MEM{str(i+1).zfill(3)}",
            "effective_date": "2022-01-01",
            "term_date": "",
            "updated_at": "2023-01-01",
        }
        patients.append(patient)
        
        # Add historical record for some patients (to demonstrate SCD Type 2)
        if random.random() < 0.3:
            old_city, old_zip = random.choice(MA_CITIES)
            old_plan_type = random.choice(PLAN_TYPES)
            historical = patient.copy()
            historical["city"] = old_city
            historical["zip_code"] = old_zip
            historical["plan_type"] = old_plan_type
            historical["updated_at"] = "2024-03-15"
            patients.append(historical)
    
    return pd.DataFrame(patients)


def generate_providers(num_providers: int) -> pd.DataFrame:
    """Generate synthetic provider data."""
    providers = []
    
    for i in range(num_providers):
        npi = generate_npi()
        specialty, category = random.choice(SPECIALTIES)
        city, zip_code = random.choice(MA_CITIES)
        
        provider = {
            "npi": npi,
            "provider_first_name": fake.first_name(),
            "provider_last_name": fake.last_name(),
            "credential": random.choice(["MD", "DO", "MD", "MD"]),
            "specialty": specialty,
            "practice_name": f"{city} {specialty} Associates",
            "address_line_1": fake.street_address(),
            "city": city,
            "state": "MA",
            "zip_code": zip_code,
            "phone": fake.phone_number()[:12],
            "accepting_new_patients": random.choice(["true", "true", "true", "false"]),
            "updated_at": "2023-01-01",
        }
        providers.append(provider)
        
        # Add historical record for some providers
        if random.random() < 0.2:
            old_city, old_zip = random.choice(MA_CITIES)
            historical = provider.copy()
            historical["practice_name"] = f"{old_city} Health Partners"
            historical["city"] = old_city
            historical["zip_code"] = old_zip
            historical["updated_at"] = "2024-01-15"
            providers.append(historical)
    
    return pd.DataFrame(providers)


def generate_claims(
    patients: pd.DataFrame,
    providers: pd.DataFrame,
    num_claims: int,
    start_date: datetime,
    end_date: datetime,
) -> pd.DataFrame:
    """Generate synthetic claims data."""
    claims = []
    
    # Get unique patients and providers
    unique_patients = patients["patient_id"].unique()
    unique_providers = providers["npi"].unique()
    
    for i in range(num_claims):
        claim_id = f"CLM{str(i+1).zfill(3)}"
        patient_id = random.choice(unique_patients)
        provider_npi = random.choice(unique_providers)
        
        # Generate service date
        days_range = (end_date - start_date).days
        service_date = start_date + timedelta(days=random.randint(0, days_range))
        paid_date = service_date + timedelta(days=random.randint(10, 45))
        
        # Select diagnosis and procedure
        diagnosis = random.choice(ICD10_CODES)
        procedure = random.choice(CPT_CODES)
        
        # Calculate amounts with some variance
        base_amount = procedure[4]
        billed = round(base_amount * random.uniform(0.9, 1.1), 2)
        allowed = round(billed * random.uniform(0.7, 0.85), 2)
        paid = round(allowed * 0.8, 2)
        patient_resp = round(allowed - paid, 2)
        
        claim = {
            "claim_id": claim_id,
            "line_number": 1,
            "patient_id": patient_id,
            "provider_npi": provider_npi,
            "diagnosis_code": diagnosis[0],
            "procedure_code": procedure[0],
            "service_date": service_date.strftime("%Y-%m-%d"),
            "paid_date": paid_date.strftime("%Y-%m-%d"),
            "place_of_service": random.choice([11, 22, 11, 11]),  # 11=Office, 22=Outpatient
            "billed_amount": billed,
            "allowed_amount": allowed,
            "paid_amount": paid,
            "patient_responsibility": patient_resp,
            "units": 1,
            "claim_status": "PAID",
        }
        claims.append(claim)
        
        # Some claims have multiple lines
        if random.random() < 0.3:
            additional_proc = random.choice([c for c in CPT_CODES if c[3] == False])
            add_billed = round(additional_proc[4] * random.uniform(0.9, 1.1), 2)
            add_allowed = round(add_billed * random.uniform(0.7, 0.85), 2)
            add_paid = round(add_allowed * 0.8, 2)
            
            additional = {
                "claim_id": claim_id,
                "line_number": 2,
                "patient_id": patient_id,
                "provider_npi": provider_npi,
                "diagnosis_code": diagnosis[0],
                "procedure_code": additional_proc[0],
                "service_date": service_date.strftime("%Y-%m-%d"),
                "paid_date": paid_date.strftime("%Y-%m-%d"),
                "place_of_service": claim["place_of_service"],
                "billed_amount": add_billed,
                "allowed_amount": add_allowed,
                "paid_amount": add_paid,
                "patient_responsibility": round(add_allowed - add_paid, 2),
                "units": 1,
                "claim_status": "PAID",
            }
            claims.append(additional)
    
    return pd.DataFrame(claims)


def main():
    parser = argparse.ArgumentParser(description="Generate synthetic healthcare data")
    parser.add_argument("--output-dir", default="../seeds", help="Output directory")
    parser.add_argument("--num-patients", type=int, default=10, help="Number of patients")
    parser.add_argument("--num-providers", type=int, default=12, help="Number of providers")
    parser.add_argument("--num-claims", type=int, default=40, help="Number of claims")
    args = parser.parse_args()
    
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"Generating synthetic data...")
    
    # Generate data
    patients = generate_patients(args.num_patients)
    providers = generate_providers(args.num_providers)
    claims = generate_claims(
        patients,
        providers,
        args.num_claims,
        datetime(2023, 1, 1),
        datetime(2023, 12, 31),
    )
    
    # Save to CSV
    patients.to_csv(output_dir / "raw_patients.csv", index=False)
    providers.to_csv(output_dir / "raw_providers.csv", index=False)
    claims.to_csv(output_dir / "raw_claims.csv", index=False)
    
    print(f"Generated:")
    print(f"  - {len(patients)} patient records")
    print(f"  - {len(providers)} provider records")
    print(f"  - {len(claims)} claim line records")
    print(f"Saved to: {output_dir}")


if __name__ == "__main__":
    main()
