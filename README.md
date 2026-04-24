# AI-Based Internship Recommendation Engine

This project is a cross-platform application designed to streamline the internship placement process. Traditional job portals often rely on basic keyword filtering, which can lead to a mismatch between a student's actual skills and the requirements of a role. This system uses a recommendation engine to rank opportunities based on technical competency alignment.

## Core Functionality

- **Profile Management:** Students define their technical background using a specific skill taxonomy rather than just a plain-text bio.
- **Automated Ranking:** The system calculates a match score for every available internship, allowing students to focus on roles where they are most qualified.
- **Recruiter Tools:** Administrators can post new listings and view applicants sorted by their calculated match percentage.
- **Data Synchronization:** Real-time updates for application statuses (e.g., "Interview Scheduled" or "Under Review") are handled through persistent Firebase database streams.

## Technical Implementation

The recommendation logic is integrated directly into the application environment. The process involves two main steps:

1. **Feature Extraction:** Using TF-IDF (Term Frequency-Inverse Document Frequency) to convert skill sets and job descriptions into numerical values.
2. **Similarity Calculation:** Applying Cosine Similarity to measure the distance between a student's profile vector and the internship's requirement vector.

The match score represents the cosine of the angle between the two vectors:

Match Score = (A · B) / (||A|| ||B||)

## Development Stack

- **Frontend:** Flutter (Dart) for Android, iOS, and Windows desktop support.
- **Backend (Serverless):** Google Firebase (Cloud Firestore for real-time data, Storage for PDF resumes, and Firebase Authentication).
- **Architecture:** Managed through a Backend-as-a-Service (BaaS) model to eliminate the need for manual server maintenance and reduce latency.

## Project Structure

- /lib: Flutter UI, state management, and the matching engine logic.
- /android, /ios, /windows: Platform-specific build configurations.

---
**Author:** Sneha Latha Reddy S
