# Physiological Signal Dataset on Meditation-Induced Relaxation: GSR, HR, and HRV Measurements in Controlled and Uncontrolled Environments

## Overview
This repository contains a publicly available dataset of physiological signals recorded during meditation sessions, designed to support research on stress regulation, emotional processing, and the autonomic nervous system (ANS). The dataset includes galvanic skin response (GSR), heart rate (HR), and heart rate variability (HRV) signals collected from 14 participants under both controlled laboratory conditions and home environments.

The study was conducted at the Department of Cybernetics and Biomedical Engineering, VSB–Technical University of Ostrava, and aims to provide high-quality physiological data for researchers working in affective computing, biofeedback, and stress management.

## Data Description
The dataset consists of 801 valid recordings, structured in JSON format. Each recording includes:
- GSR signal sampled at 10 Hz
- HR and HRV signals sampled at 1 Hz
- Environmental metadata (room temperature, humidity, CO₂ levels)
- Questionnaire responses (participant’s mood, sleep quality, focus level)


Each recording is segmented into three phases:
1. Pre-meditation (baseline state)
2. Meditation phase (controlled breathing exercise)
3. Post-meditation (return to normal state)

A subset of the dataset also includes MBTI-based personality and health questionnaire, enabling additional research on the interaction between personality traits and physiological responses.

## Experimental Setup
The physiological signals were recorded using:
- Sensetio wristband for GSR measurements
- Polar H10 chest strap for HR and HRV monitoring
- Smart home laboratory sensors for environmental data logging

Participants performed a guided breathing-focused meditation exercise, following a controlled rhythm (4-6-8 seconds per breath cycle). The signals were collected both in a biotelemetric laboratory and at home to compare responses under different conditions.

## Data Processing and Feature Extraction
The dataset underwent artifact removal and preprocessing to ensure data integrity. GSR signals were decomposed into tonic and phasic activity using continuous decomposition analysis (Ledalab), and HRV features were extracted in the time domain.
Key extracted features:
- GSR signal:
    - Phasic activity area under the curve
    - Mean amplitude of peaks
    - Number of peaks
    - Entropy and second moment of peaks
- HRV signal:
    - Mean heart rate (HR)
    - Standard deviation of RR intervals (SDNN)
    - Root mean square of successive RR differences (RMSSD)
    - pNN50 (percentage of successive RR intervals > 50ms)

Normalization was applied to account for inter-subject variability.

## Scientific Contributions
This dataset enables the investigation of:
- Effects of meditation on stress physiology through GSR and HRV analysis
- ANS regulation mechanisms and their variability across different environments
- Potential biomarkers of stress resilience derived from physiological signals
- The role of personality traits in emotion regulation during meditation

The findings contribute to the fields of psychophysiology, affective computing, mental health monitoring, and wearable biosensing.

## How to Use the Data
The dataset is structured in a user-friendly format, enabling straightforward integration into machine learning and statistical analysis pipelines. Example scripts for data loading, visualization, and feature extraction are provided in the repository.
Researchers are encouraged to cite this dataset in publications and explore its applications in computational neuroscience, biofeedback interventions, and emotion recognition.
For questions or collaborations, please contact: jan.kubicek@vsb.cz

## License
This dataset is released under the Creative Commons (CC-BY 4.0), allowing for academic and commercial research use with proper attribution.

