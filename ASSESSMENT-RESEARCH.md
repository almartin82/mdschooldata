# Maryland Assessment Data Research

## Summary

Maryland has a rich assessment history with multiple testing systems. This document outlines the assessment data sources available for Maryland public schools.

## Assessment Systems and Timeline

### 1. Maryland School Assessment (MSA)
- **Years**: ~2003-2014
- **Grades**: 3-8
- **Subjects**: Reading, Math, Science (grades 5 and 8)
- **Status**: Retired

### 2. High School Assessments (HSA)
- **Years**: ~2003-2015
- **Grades**: High School
- **Subjects**: Biology, Algebra, English, Government
- **Status**: Retired

### 3. PARCC (Partnership for Assessment of Readiness for College and Careers)
- **Years**: 2015-2019
- **Grades**: 3-8, High School (English II, Algebra I, Algebra II)
- **Subjects**: English Language Arts (ELA), Mathematics
- **Status**: Retired (2015 was first year, 2019 was last year)

### 4. MCAP (Maryland Comprehensive Assessment Program)
- **Years**: 2021-present
- **Grades**: 3-8, High School
- **Subjects**:
  - ELA (English Language Arts) - Grades 3-8, 10
  - Mathematics - Grades 3-8, Algebra I, Algebra II, Geometry
  - Science - Grades 5, 8, High School (MISA)
  - Social Studies - Grade 8, High School Government
- **Status**: Current (started 2021-2022 school year)

## Data Sources

### Primary Source: Maryland Report Card

**URL**: https://reportcard.msde.maryland.gov/Graphs/

**Description**: The Maryland Report Card is the official MSDE data portal. It provides:
- Interactive data visualization
- CSV download functionality for filtered data
- State, district, and school-level data
- Multiple years of assessment results

**Download Pattern**: The site uses a hash-based URL structure for downloads:
```
https://reportcard.msde.maryland.gov/Graphs/#/DataDownloads/datadownload/3/17/6/99/XXXX
```

Where XXXX appears to be a hash or identifier for the specific data view.

**Challenge**: The Report Card site uses JavaScript to generate download links dynamically, making direct URL discovery challenging.

### Secondary Sources

1. **MCAP Results Presentations (PDFs)**
   - URL: https://marylandpublicschools.org/stateboard/Documents/
   - Contains summary data in PDF format
   - Not machine-readable
   - Years: 2021-2024

2. **MCAP ESEA File Field Definitions**
   - URL: https://support.mdassessments.com/reporting/
   - Documents available for 2021-2022, 2022-2023, 2023-2024
   - Provides data structure for ESEA (Every Student Succeeds Act) files
   - Field definitions for ELA, Math, Science, Social Studies

3. **MSDE Assessment Pages**
   - MCAP Math: https://marylandpublicschools.org/about/pages/daait/assessment/mcap/math.aspx
   - MCAP ELA: https://marylandpublicschools.org/about/pages/daait/assessment/mcap/ela.aspx
   - MCAP Social Studies: https://marylandpublicschools.org/about/pages/daait/assessment/mcap/socialstudies.aspx
   - EOC Assessments: https://marylandpublicschools.org/about/pages/daait/assessment/eocs/index.aspx

## Data Availability

### MCAP Data (2021-present)

| School Year | End Year | Subjects | Grades | Status |
|-------------|----------|----------|--------|--------|
| 2021-2022 | 2022 | ELA, Math, Science | 3-8, HS | Available |
| 2022-2023 | 2023 | ELA, Math, Science | 3-8, HS | Available |
| 2023-2024 | 2024 | ELA, Math, Science | 3-8, HS | Available |
| 2024-2025 | 2025 | ELA, Math, Science, Social Studies | 3-8, HS | Available |

**Note**: Social Studies data became available starting 2024-2025.

### Historical Data (Pre-2021)

| Assessment | Years | Subjects | Grades | Availability |
|------------|-------|----------|--------|--------------|
| PARCC | 2015-2019 | ELA, Math | 3-8, HS | May be available through archives |
| MSA | 2003-2014 | Reading, Math, Science | 3, 5-8 | May require special access |
| HSA | 2003-2015 | Biology, Algebra, English, Gov | HS | May require special access |

## Implementation Strategy

### Phase 1: MCAP Data (2021-2025)

**Approach**: Since Maryland Report Card uses dynamic JavaScript for downloads, we'll implement a hybrid approach:

1. **Document Manual Download Workflow**
   - Provide clear instructions for users to download from Maryland Report Card
   - Create `import_local_assessment()` function to load locally saved files

2. **Attempt URL Pattern Discovery**
   - Try to reverse-engineer the download URL hash pattern
   - Implement automated download if pattern is discoverable

3. **Data Structure**
   - Parse CSV files downloaded from Report Card
   - Standardize column names across years
   - Add is_state, is_district, is_school helper columns

### Phase 2: Historical Data (Pre-2021)

**Approach**: Add historical PARCC/MSA data if accessible:
- Search for archived PARCC data files
- Check if MSDE has historical data portals
- Implement as separate functions if data structure differs

## Data Fields Expected

Based on MCAP ESEA File Field Definitions, the data should include:

- **Identifiers**:
  - State code, District code, School code
  - School year, Assessment type
  - Grade level

- **Student Groups**:
  - All Students
  - Race/Ethnicity (White, Black, Hispanic, Asian, Multiracial, etc.)
  - Special Education, ELL, FARM (Free/Reduced Meals)

- **Performance Metrics**:
  - Number tested
  - Percent proficient (Levels 3+4 combined)
  - Mean scale score (if available)
  - Performance level distribution

- **Subjects**:
  - ELA (English Language Arts)
  - Mathematics
  - Science (MISA)
  - Social Studies (Government)

## Next Steps

1. Create `get_raw_assessment()` function with manual download documentation
2. Implement URL pattern discovery for Maryland Report Card downloads
3. Create `process_assessment()` and `tidy_assessment()` for data standardization
4. Add test cases for 2021-2025 MCAP data
5. Investigate historical PARCC/MSA data availability

## Known Challenges

1. **Dynamic Download URLs**: Maryland Report Card uses JavaScript-generated download links
2. **API Access**: No publicly documented API for Report Card data
3. **Historical Data**: Pre-MCAP data may not be readily accessible
4. **Authentication**: Some data sources may require login or special permissions

## Sources

- Maryland Report Card: https://reportcard.msde.maryland.gov/Graphs/
- MCAP Assessment Pages: https://marylandpublicschools.org/about/pages/daait/assessment/
- MCAP Support Portal: https://support.mdassessments.com/reporting/
- MCAP Results Presentations: https://marylandpublicschools.org/stateboard/Documents/
