import pandas as pd

# Load data
df = pd.read_csv('WA_Fn-UseC_-Telco-Customer-Churn.csv')

# Clean
df['TotalCharges'] = pd.to_numeric(df['TotalCharges'], errors='coerce')
df['TotalCharges'] = df['TotalCharges'].fillna(df['MonthlyCharges'])
df['Churn_Flag'] = df['Churn'].apply(lambda x: 1 if x == 'Yes' else 0)
df['CLV'] = df['MonthlyCharges'] * df['tenure']
df['Tenure_Group'] = pd.cut(df['tenure'],
    bins=[0, 12, 24, 36, 48, 60, 72],
    labels=['0-12', '13-24', '25-36', '37-48', '49-60', '61+'])
df['Service_Count'] = df[['PhoneService', 'OnlineSecurity', 'OnlineBackup',
    'DeviceProtection', 'TechSupport', 'StreamingTV', 'StreamingMovies']].apply(
    lambda x: (x == 'Yes').sum(), axis=1)

# Export
df.to_csv('churn_powerbi.csv', index=False)
print(f" Exported {len(df)} rows to churn_powerbi.csv")