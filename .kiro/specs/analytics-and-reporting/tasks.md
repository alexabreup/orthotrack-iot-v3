# Implementation Plan - Sistema de Analytics e Relatórios

## Task List

- [ ] 1. Setup database schema and aggregation tables
  - Create migration files for new analytics tables
  - Add indexes for performance optimization
  - Create database functions for common aggregations
  - _Requirements: 11.1, 11.6_

- [ ] 2. Implement backend analytics service layer
- [ ] 2.1 Create analytics service structure and interfaces
  - Define service interfaces and data structures
  - Setup dependency injection for database and cache
  - Create error types and constants
  - _Requirements: All_

- [ ] 2.2 Implement compliance calculation functions
  - Create function to calculate daily compliance
  - Create function to calculate average compliance
  - Create function to calculate compliance streaks
  - _Requirements: 1.2, 3.4, 3.5_

- [ ]* 2.3 Write property test for compliance calculation
  - **Property 1: Compliance Calculation Formula**
  - **Validates: Requirements 1.2**

- [ ] 2.4 Implement usage statistics calculations
  - Create function for average daily usage
  - Create function for session count
  - Create function for average session duration
  - _Requirements: 3.1, 3.2, 3.3_

- [ ]* 2.5 Write property tests for usage statistics
  - **Property 4: Average Daily Usage Calculation**
  - **Property 5: Session Count Accuracy**
  - **Property 6: Average Session Duration**
  - **Validates: Requirements 3.1, 3.2, 3.3**

- [ ] 2.6 Implement usage pattern aggregations
  - Create function for hourly distribution
  - Create function for weekly distribution
  - Create function to identify top usage hours
  - _Requirements: 4.2, 4.4, 5.2_

- [ ]* 2.7 Write property tests for usage patterns
  - **Property 8: Hourly Distribution Aggregation**
  - **Property 9: Top Hours Highlighting**
  - **Property 10: Weekly Distribution Calculation**
  - **Property 11: Day of Week Ordering**
  - **Validates: Requirements 4.2, 4.4, 5.2, 5.4**

- [ ] 3. Implement caching layer with Redis
- [ ] 3.1 Create cache manager service
  - Implement cache key generation functions
  - Create cache get/set/delete operations
  - Implement cache invalidation logic
  - _Requirements: 11.2, 11.3, 11.4_

- [ ]* 3.2 Write property tests for cache behavior
  - **Property 24: Cache Invalidation on Data Insert**
  - **Property 25: Cache Hit Before Database Query**
  - **Validates: Requirements 11.3, 11.4**

- [ ] 3.3 Integrate cache with analytics service
  - Add cache checks before database queries
  - Implement cache population on misses
  - Add cache invalidation on data updates
  - _Requirements: 11.2, 11.3, 11.4_

- [ ] 4. Implement analytics API endpoints
- [ ] 4.1 Create patient metrics endpoint
  - Implement GET /api/v1/analytics/patients/:id/metrics
  - Add request validation and error handling
  - Integrate with analytics service and cache
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 4.2 Create compliance data endpoint
  - Implement GET /api/v1/analytics/patients/:id/compliance
  - Add date range filtering
  - Include institution average calculation
  - _Requirements: 1.1, 1.2, 12.1, 12.2, 12.3_

- [ ]* 4.3 Write property test for institution average filtering
  - **Property 27: Institution Average Filtering**
  - **Validates: Requirements 12.2**

- [ ] 4.4 Create usage patterns endpoint
  - Implement GET /api/v1/analytics/patients/:id/usage-patterns
  - Return hourly and weekly distributions
  - _Requirements: 4.1, 4.2, 5.1, 5.2_

- [ ] 4.5 Create institution dashboard endpoint
  - Implement GET /api/v1/analytics/institution/dashboard
  - Calculate all institution-level metrics
  - Optimize for performance with aggregations
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

- [ ]* 4.6 Write property tests for institution metrics
  - **Property 16: Institution Dashboard Patient Count**
  - **Property 17: Institution Average Compliance**
  - **Property 18: Device Status Categorization**
  - **Property 19: Top/Bottom Patient Lists**
  - **Property 20: Compliance Distribution Bucketing**
  - **Validates: Requirements 8.1, 8.2, 8.3, 8.4, 8.5, 8.6**

- [ ] 4.7 Create timeline events endpoint
  - Implement GET /api/v1/analytics/patients/:id/timeline
  - Fetch and aggregate events from multiple sources
  - Implement event ordering and filtering
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.6_

- [ ]* 4.8 Write property tests for timeline
  - **Property 21: Timeline Event Ordering**
  - **Property 22: Inactivity Period Detection**
  - **Validates: Requirements 9.4, 9.6**

- [ ] 4.9 Create sensor data endpoint
  - Implement GET /api/v1/analytics/patients/:id/sensors
  - Return time-series data for all sensor types
  - Implement anomaly detection
  - _Requirements: 10.1, 10.2, 10.3, 10.5_

- [ ]* 4.10 Write property test for anomaly detection
  - **Property 23: Sensor Anomaly Detection**
  - **Validates: Requirements 10.5**

- [ ] 5. Checkpoint - Ensure all backend tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Implement PDF report generation
- [ ] 6.1 Setup PDF generation library
  - Install and configure PDF library (e.g., gofpdf or wkhtmltopdf)
  - Create PDF template structure
  - Setup file storage for generated reports
  - _Requirements: 6.1_

- [ ] 6.2 Implement PDF report builder
  - Create header with logo and institution info
  - Add patient demographics section
  - Add executive summary section
  - Add compliance chart rendering
  - Add daily usage table
  - Add footer with pagination
  - _Requirements: 6.2, 6.3, 6.4, 6.5, 6.6, 6.7_

- [ ]* 6.3 Write property test for PDF content completeness
  - **Property 12: PDF Content Completeness**
  - **Validates: Requirements 6.2, 6.3, 6.4, 6.5, 6.6, 6.7**

- [ ] 6.4 Create PDF export endpoint
  - Implement POST /api/v1/reports/pdf
  - Generate PDF asynchronously if needed
  - Return download URL
  - _Requirements: 6.1, 6.8_

- [ ] 7. Implement Excel report generation
- [ ] 7.1 Setup Excel generation library
  - Install and configure Excel library (e.g., excelize)
  - Create Excel template structure
  - _Requirements: 7.1_

- [ ] 7.2 Implement Excel report builder
  - Create "Resumo" sheet with aggregated stats
  - Create "Uso Diário" sheet with daily compliance
  - Create "Sessões" sheet with session details
  - Create "Telemetria" sheet with sensor readings
  - Apply date formatting (DD/MM/YYYY HH:MM:SS)
  - Apply conditional formatting for compliance cells
  - _Requirements: 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_

- [ ]* 7.3 Write property tests for Excel structure and formatting
  - **Property 13: Excel Sheet Structure**
  - **Property 14: Excel Date Formatting**
  - **Property 15: Excel Conditional Formatting**
  - **Validates: Requirements 7.2, 7.3, 7.4, 7.5, 7.6, 7.7**

- [ ] 7.4 Create Excel export endpoint
  - Implement POST /api/v1/reports/excel
  - Generate Excel file
  - Return download URL
  - _Requirements: 7.1, 7.8_

- [ ] 8. Implement frontend analytics dashboard
- [ ] 8.1 Create date range selector component
  - Build UI for predefined periods (7d, 30d, 90d, etc.)
  - Add custom date range picker
  - Implement date validation
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [ ]* 8.2 Write property test for date range validation
  - **Property 3: Date Range Validation**
  - **Validates: Requirements 2.5**

- [ ] 8.3 Create patient metrics cards component
  - Display average daily usage
  - Display total sessions
  - Display average session duration
  - Display average compliance
  - Display current streak
  - Handle empty data states
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [ ] 8.4 Create compliance chart component
  - Implement line chart with Chart.js or similar
  - Add tooltip on hover
  - Implement color coding (red/yellow/green)
  - Add institution average reference line
  - _Requirements: 1.1, 1.3, 1.4, 1.5, 1.6, 12.1, 12.5_

- [ ]* 8.5 Write property test for compliance color coding
  - **Property 2: Compliance Color Coding**
  - **Validates: Requirements 1.4, 1.5, 1.6**

- [ ] 8.6 Create usage pattern charts
  - Implement hourly distribution bar chart
  - Implement weekly distribution bar chart
  - Add tooltips with detailed info
  - Highlight top usage hours
  - _Requirements: 4.1, 4.3, 4.4, 5.1, 5.3, 5.4_

- [ ] 8.7 Create timeline component
  - Display events chronologically
  - Add markers for alerts, prescription changes, inactivity
  - Implement popover for event details
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

- [ ] 8.8 Create sensor data charts
  - Implement temperature trend chart
  - Implement battery level chart
  - Implement accelerometer magnitude chart
  - Add zoom and pan functionality
  - Highlight anomalous values
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6_

- [ ] 8.9 Create comparison indicator component
  - Show patient vs institution average
  - Display "above"/"below"/"equal" indicator
  - Show tooltip with details
  - Handle insufficient data case
  - _Requirements: 12.3, 12.4, 12.5_

- [ ]* 8.10 Write property test for comparison indicator
  - **Property 28: Comparison Indicator**
  - **Validates: Requirements 12.3**

- [ ] 9. Implement export functionality in frontend
- [ ] 9.1 Create export button component
  - Add PDF export button
  - Add Excel export button
  - Show loading state during generation
  - Handle download on completion
  - Display error messages on failure
  - _Requirements: 6.1, 6.8, 7.1, 7.8_

- [ ] 9.2 Integrate export with backend API
  - Call PDF export endpoint
  - Call Excel export endpoint
  - Handle file download
  - Add error handling and retry logic
  - _Requirements: 6.1, 6.8, 7.1, 7.8_

- [ ] 10. Implement institution dashboard
- [ ] 10.1 Create institution dashboard page
  - Display total active patients
  - Display average compliance
  - Display device status counts
  - Show compliance distribution chart
  - _Requirements: 8.1, 8.2, 8.3, 8.6_

- [ ] 10.2 Create patient ranking lists
  - Display top 10 lowest compliance patients
  - Display top 10 highest compliance patients
  - Make patient names clickable to navigate
  - _Requirements: 8.4, 8.5, 8.7_

- [ ] 11. Implement performance optimizations
- [ ] 11.1 Add database query optimizations
  - Review and optimize slow queries
  - Ensure all indexes are in place
  - Use EXPLAIN ANALYZE for query tuning
  - _Requirements: 11.1, 11.6_

- [ ] 11.2 Implement aggregation background jobs
  - Create job to pre-calculate daily compliance
  - Create job to pre-calculate hourly distributions
  - Create job to pre-calculate weekly distributions
  - Schedule jobs to run nightly
  - _Requirements: 11.1, 11.6_

- [ ] 11.3 Add frontend performance optimizations
  - Implement lazy loading for charts
  - Add debouncing for filter changes
  - Memoize computed values
  - Optimize re-renders
  - _Requirements: 11.5_

- [ ]* 11.4 Write property test for response time
  - **Property 26: Response Time Performance**
  - **Validates: Requirements 11.5**

- [ ] 12. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 13. Integration testing and bug fixes
- [ ] 13.1 Test complete user flows
  - Test viewing patient analytics
  - Test filtering by different periods
  - Test exporting PDF reports
  - Test exporting Excel reports
  - Test institution dashboard
  - _Requirements: All_

- [ ] 13.2 Test edge cases
  - Test with no data
  - Test with partial data
  - Test with large datasets (1 year)
  - Test with invalid inputs
  - Test concurrent requests
  - _Requirements: 2.6, 3.6, 4.5, 5.5, 12.4_

- [ ] 13.3 Performance testing
  - Load test with 100 concurrent users
  - Verify response times < 2 seconds
  - Check cache hit rates
  - Monitor database query performance
  - _Requirements: 11.5_

- [ ] 13.4 Fix identified bugs and issues
  - Address any bugs found during testing
  - Optimize any slow operations
  - Improve error messages
  - _Requirements: All_

- [ ] 14. Documentation and deployment preparation
- [ ] 14.1 Update API documentation
  - Document all new endpoints in Swagger
  - Add request/response examples
  - Document error codes
  - _Requirements: All_

- [ ] 14.2 Create user guide
  - Document how to use analytics dashboard
  - Document how to export reports
  - Add screenshots and examples
  - _Requirements: All_

- [ ] 14.3 Prepare deployment
  - Update environment variables
  - Create database migrations
  - Setup monitoring and alerts
  - Prepare rollback plan
  - _Requirements: All_
