SELECT*
FROM[dbo].[Copy of NHS_Cancer_Data]

---🧍 Demographics and patient characteristics

---1. Count male vs female patients and calculate their percentage share.

SELECT 
    COUNT(CASE WHEN [Sex] = 'Male' THEN 1 END) AS MaleCount,
    COUNT(CASE WHEN [Sex] = 'Female' THEN 1 END) AS FemaleCount,
    
    CAST(COUNT(CASE WHEN [Sex] = 'Male' THEN 1 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS MalePercentage,
    CAST(COUNT(CASE WHEN [Sex] = 'Female' THEN 1 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS FemalePercentage
FROM 
    [dbo].[Copy of NHS_Cancer_Data];


---  Find the average age at diagnosis using Primary_Diagnosis_Date - Date_of_Birth.

SELECT AVG(DATEDIFF(YEAR,[Date_of_Birth],[Primary_Diagnosis_Date])) AS Avg_Age_At_Diagnosis

FROM[dbo].[Copy of NHS_Cancer_Data]


--- 3. Identify GP practices with the highest number of registered cancer patients.

  
SELECT COUNT(*) AS CANCER_PATIENT,[GP_Practice_Code]
FROM [dbo].[Copy of NHS_Cancer_Data]
WHERE[Vital_Status]='Alive'
GROUP BY [GP_Practice_Code]
HAVING COUNT(*)>=2;  

SELECT TOP 10 
    [GP_Practice_Code], 
    COUNT(*) AS CancerPatients
FROM [dbo].[Copy of NHS_Cancer_Data]
WHERE [Vital_Status] = 'Alive'
GROUP BY [GP_Practice_Code]
ORDER BY CancerPatients DESC;



--- 4. List postcode areas (first 1–2 characters) and count patients in each.

SELECT LEFT([Postcode],2)AS POSTCODE_AREA,
       COUNT([Local_Patient_ID]) AS PATIENT_COUNT
FROM [dbo].[Copy of NHS_Cancer_Data]
GROUP BY 
    LEFT([Postcode], 2)
ORDER BY 
    POSTCODE_AREA;


--- 5. Detect duplicate NHS_Number values and list all rows involved.

SELECT TOP 500 [NHS_Number]
      ,ROW_NUMBER() OVER(PARTITION BY [Local_Patient_ID],[Date_of_Birth]ORDER BY [NHS_Number]) AS DUPLICATE_NHS_NUMBER
      ,[Local_Patient_ID]
      ,[Date_of_Birth]
      ,[Sex]
      ,[Postcode]
      ,[GP_Practice_Code]
      ,[Referral_Date]
      ,[First_Seen_Date]
      ,[MDT_Date]
      ,[Decision_to_Treat_Date]
      ,[Treatment_Start_Date]
      ,[Primary_Diagnosis_Date]
      ,[Primary_Tumour_Site_ICD10]
      ,[Morphology_ICDO3]
      ,[Behaviour_Code]
      ,[Laterality]
      ,[Grade]
      ,[Stage_Group_TNM]
      ,[Basis_of_Diagnosis]
      ,[Treatment_Modality]
      ,[Treatment_Intent]
      ,[Treatment_Provider]
      ,[Treatment_Outcome]
      ,[Recurrence_Indicator]
      ,[Recurrence_Date]
      ,[Vital_Status] 
FROM [dbo].[Copy of NHS_Cancer_Data]
ORDER BY [Local_Patient_ID],[Date_of_Birth]DESC


--- 🧫 Tumour site, morphology, and staging

--- 1. Count patients by Primary_Tumour_Site_ICD10 and return the top five.

SELECT TOP 5 [Primary_Tumour_Site_ICD10]
          ,COUNT(*) AS PATIENT_COUNT
FROM[dbo].[Copy of NHS_Cancer_Data]
GROUP BY[Primary_Tumour_Site_ICD10]
ORDER BY PATIENT_COUNT

--- 2. Count distinct Morphology_ICDO3 codes and list their frequencies.

SELECT DISTINCT ([Morphology_ICDO3])
            ,COUNT(*) AS FREQUENCIES
FROM[dbo].[Copy of NHS_Cancer_Data]
GROUP BY [Morphology_ICDO3]
ORDER BY FREQUENCIES DESC

--- 3. Calculate the number of patients in each Stage_Group_TNM category.

SELECT [Stage_Group_TNM]
      ,COUNT(*) AS NUMBER_OF_PATIENTS
FROM[dbo].[Copy of NHS_Cancer_Data]
GROUP BY [Stage_Group_TNM]
ORDER BY NUMBER_OF_PATIENTS DESC

--- 4. Determine whether certain tumour sites are associated with later stages (e.g., Stage III/IV).

SELECT [Primary_Tumour_Site_ICD10]
     ,COUNT(*) AS Late_Stage_Count
FROM [dbo].[Copy of NHS_Cancer_Data]
WHERE [Stage_Group_TNM]  IN ('Stage III', 'Stage IV')
GROUP BY [Primary_Tumour_Site_ICD10]
ORDER BY Late_Stage_Count DESC;

--- 5. Identify the tumour site with the highest proportion of Stage IV cases.

SELECT TOP 1
     [Primary_Tumour_Site_ICD10]
     ,COUNT(CASE WHEN [Stage_Group_TNM]= 'STAGE IV' THEN 1 END)*100.0/COUNT (*) AS PERCENTAGE_OF_STAGE
FROM [dbo].[Copy of NHS_Cancer_Data]
WHERE [Stage_Group_TNM]  IN ('Stage IV')
GROUP BY [Primary_Tumour_Site_ICD10]
ORDER BY PERCENTAGE_OF_STAGE;


--- 🏥 Pathway timing and performance
--- 1. Calculate the average number of days between Referral_Date and First_Seen_Date.

SELECT AVG(DATEDIFF(DAY,[Referral_Date],[First_Seen_Date])*1.0) AS AVGNUMBER_OF_DAYS
FROM[dbo].[Copy of NHS_Cancer_Data]

--- 2. Calculate the median time between Decision_to_Treat_Date and Treatment_Start_Date.

SELECT TOP 1
    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY DATEDIFF(day,[Decision_to_Treat_Date], [Treatment_Start_Date])
    ) OVER () AS Median_Days
FROM [dbo].[Copy of NHS_Cancer_Data]
    

--- 3. Count how many patients started treatment within 31 days of decision to treat.

SELECT COUNT(*) AS PatientsWithin31Days
FROM [dbo].[Copy of NHS_Cancer_Data]
WHERE DATEDIFF(DAY,[Decision_to_Treat_Date],[Treatment_Start_Date]) BETWEEN 0 AND 31;


---4. Identify patients whose MDT_Date occurs after Treatment_Start_Date (data quality check).

SELECT *
FROM [dbo].[Copy of NHS_Cancer_Data]
WHERE [MDT_Date] > [Treatment_Start_Date]

---5. Compare pathway durations (Referral → Treatment_Start) across tumour sites and rank them.

SELECT 
    [Primary_Tumour_Site_ICD10],
    COUNT(*) AS PatientCount,
    AVG(DATEDIFF(day,[Referral_Date] ,[Treatment_Start_Date] )) AS AvgDurationDays,
    RANK() OVER (ORDER BY AVG(DATEDIFF(day,[Referral_Date] ,[Treatment_Start_Date] ))DESC) AS DurationRank
FROM [dbo].[Copy of NHS_Cancer_Data]
WHERE [Referral_Date] IS NOT NULL 
  AND [Treatment_Start_Date] IS NOT NULL
GROUP BY[Primary_Tumour_Site_ICD10] 
ORDER BY DurationRank;

💊 Treatment patterns and outcomes


--- 1. Count patients by Treatment_Modality (e.g., Surgery, Radiotherapy, Chemotherapy).

SELECT 
       COUNT (CASE WHEN [Treatment_Modality]= 'Chemotherapy' THEN 1 END) AS Chemotherapy_Patient,
       COUNT (CASE WHEN [Treatment_Modality]= 'Hormonetherapy' THEN 1 END) AS Hormonetherapy_Patient,
       COUNT (CASE WHEN [Treatment_Modality]= 'Immunotherapy' THEN 1 END) AS Immunotherapy_Patient,
       COUNT (CASE WHEN [Treatment_Modality]= 'Radiotherapy' THEN 1 END) AS Radiotherapy_Patient,
       COUNT (CASE WHEN [Treatment_Modality]= 'Surgery' THEN 1 END) AS Surgery_Patient,
       COUNT (CASE WHEN [Treatment_Modality]= 'None' THEN 1 END) AS None_Patient

FROM [dbo].[Copy of NHS_Cancer_Data];


---2. Determine which modality has the highest proportion of Complete response outcomes.							

SELECT [Treatment_Modality],

    COUNT(*) AS TotalPatients,
    COUNT(CASE WHEN [Treatment_Outcome] = 'Complete response' THEN 1 END) AS CompleteResponses,
    CAST(COUNT(CASE WHEN [Treatment_Outcome] = 'Complete response' THEN 1 END) * 100.0 / COUNT(*) AS DECIMAL(5, 2)) AS CompleteResponsePercentage
FROM [dbo].[Copy of NHS_Cancer_Data]
WHERE [Treatment_Modality] IS NOT NULL
  AND [Treatment_Outcome] IS NOT NULL
GROUP BY [Treatment_Modality]
ORDER BY CompleteResponsePercentage DESC;


--- 3 Count how many patients have a Recurrence_Indicator and calculate average time to recurrence.

SELECT 
       COUNT (*) AS [Recurrent Count],
       AVG(DATEDIFF(Month,[Treatment_Start_Date],[Recurrence_Date])*1.0) AS AvgMonthsToRecurrence
       FROM [dbo].[Copy of NHS_Cancer_Data]
       WHERE [Recurrence_Indicator] = 'TRUE'
  AND [Treatment_Start_Date] IS NOT NULL
  AND [Recurrence_Date] IS NOT NULL;
       
       
--- 4. Compare Treatment_Intent (Curative, Palliative, etc.) across tumour sites.

SELECT 
    [Primary_Tumour_Site_ICD10],
    COUNT(*) AS TotalPatients,
    SUM(CASE WHEN [Treatment_Intent] = 'Curative' THEN 1 ELSE 0 END) AS CurativeCount,
    SUM(CASE WHEN [Treatment_Intent] = 'Palliative' THEN 1 ELSE 0 END) AS PalliativeCount,
    SUM(CASE WHEN [Treatment_Intent] = 'Unknown' THEN 1 ELSE 0 END) AS UnknownCount

FROM [dbo].[Copy of NHS_Cancer_Data]
GROUP BY [Primary_Tumour_Site_ICD10]
ORDER BY [Primary_Tumour_Site_ICD10] DESC;

--- 5. For deceased patients, calculate the average time from Treatment_Start_Date to Date_of_Death.

SELECT
      COUNT (*) AS Total_Patient,
      COUNT(CASE WHEN [Vital_Status] = 'Deceased' then 1 end) AS Deceased_Patient,
      AVG(DATEDIFF(YEAR,[Treatment_Start_Date],[Date_of_Death])* 1.0) AS [AVG Time To Death]
      FROM [dbo].[Copy of NHS_Cancer_Data]
