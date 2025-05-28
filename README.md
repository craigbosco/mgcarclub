# MG Car Club - AWS Backend Infrastructure

A serverless AWS backend system for managing MG Car Club event registrations, specifically designed for the **MG Jamboree 2025: Cars in Paradise** event. This infrastructure provides a complete form submission pipeline with secure data storage, real-time notifications, and payment processing integration.

## 🏗️ Architecture Overview

The system is built on AWS using a serverless architecture with the following components:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   API Gateway   │    │    Lambda       │
│  (HTML Form)    │───▶│   (REST API)    │───▶│   (Python)      │
│  + PayPal JS    │    │  + API Keys     │    │ jamboree_register│
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                       ┌─────────────────┐             │
                       │   DynamoDB      │◀────────────┘
                       │  (Registration  │
                       │     Data)       │
                       └─────────────────┘
                                │
                       ┌─────────────────┐
                       │      SNS        │◀─────────────────┐
                       │ (Notifications) │                  │
                       └─────────────────┘                  │
                                │                           │
                       ┌─────────────────┐                  │
                       │   Email Alerts  │                  │
                       │  (Club Leaders) │                  │
                       └─────────────────┘                  │
                                                           │
                       ┌─────────────────┐                  │
                       │   CloudWatch    │◀─────────────────┘
                       │     Logs        │
                       └─────────────────┘
```

## 📁 Repository Structure

```
mgcarclub/
├── README.md                           # This file
├── docs/                              # Frontend assets and test files
│   ├── jamboree_form.html            # Main registration form with PayPal integration
│   ├── api_test.html                 # API testing interface (v1)
│   ├── api_test_v2.html              # Enhanced API testing interface
│   ├── index.html                    # Landing page
│   └── secrets.js                    # API configuration (not committed)
├── infra/                            # AWS CloudFormation infrastructure
│   └── website-forms/
│       ├── template.yml              # Main CloudFormation template
│       ├── deploy-stack.sh           # Deployment automation script
│       ├── params-prod.json          # Production parameters
│       ├── stack-config.yml          # Stack configuration
│       └── resource-templates/       # Modular CloudFormation templates
│           ├── template-iamcore.yml     # IAM roles and policies
│           ├── template-registration-action.yml  # Lambda & DynamoDB
│           └── template-apigw.yml       # API Gateway configuration
└── src/                              # Application source code
    └── services/
        └── jamboree_register/
            ├── requirements.txt      # Python dependencies
            └── app/
                └── jamboree_register.py  # Lambda function handler
```

## 🚀 Key Features

### **Event Registration System**
- **Dual Registration Types**: Car Show only or Car Show + Boat Tour
- **Attendee Management**: Support for multiple attendees per registration
- **Vehicle Information**: Year/Make/Model tracking for car show participants
- **Digital Waiver**: Electronic signature acceptance
- **Payment Integration**: PayPal payment processing with amount tracking

### **Data Management**
- **Secure Storage**: All registration data stored in DynamoDB with unique IDs
- **Real-time Processing**: Immediate data validation and storage
- **Audit Trail**: Timestamps and production/test environment flags

### **Notification System**
- **Multi-recipient Alerts**: Automatic email notifications to club leadership
- **Structured Messaging**: Formatted registration details in notifications
- **SNS Integration**: Reliable message delivery through AWS SNS

### **Security & Compliance**
- **API Key Authentication**: Secure access to endpoints
- **CORS Support**: Properly configured cross-origin requests
- **Environment Separation**: Production and development configurations
- **IAM Policies**: Least-privilege access controls

## 🔧 Technical Components

### **AWS Lambda Function** (`jamboree_register.py`)
**Runtime**: Python 3.12  
**Handler**: `app.jamboree_register.lambda_handler`  
**Timeout**: 30 seconds

**Input Data Processing**:
- `firstName`, `lastName`, `email` (required)
- `attendees`, `address`, `phone` (optional)
- `yearMakeModel`, `signature` (car show details)
- `eventType` (`carShow` or `boatTour`)
- `participants`, `amount`, `paymentDetails` (payment info)

**Data Flow**:
1. **Validation** → Required field checking
2. **Storage** → DynamoDB record creation with UUID
3. **Notification** → SNS message to club leadership
4. **Response** → Success confirmation with registration ID

### **DynamoDB Table** (`RegistrationTable`)
**Billing Mode**: Pay-per-request  
**Primary Key**: `id` (String, UUID)

**Stored Attributes**:
- Registration metadata (id, timestamp, is_production)
- Personal information (firstName, lastName, email, phone, address)
- Event details (eventType, attendees, participants)
- Vehicle information (yearMakeModel)
- Payment data (amount, paymentDetails)
- Legal compliance (signature acceptance)

### **API Gateway**
**Type**: REST API  
**Stage**: v1  
**Method**: POST `/register`  
**Authentication**: API Key required  
**Features**:
- Request/response logging
- Metrics collection
- CORS enabled
- Rate limiting via usage plans

### **SNS Topic** (`RegistrationTopic`)
**Subscribers**:
- `craigbosco@mac.com` (Primary contact)
- `gail@glennsmg.com` (Club Secretary)
- `spicerlor@gmail.com` (Club Finance Officer)

**Message Format**: Structured text with all registration details

## 🏃‍♂️ Deployment

### **Prerequisites**
- AWS CLI configured with appropriate permissions
- CloudFormation deployment permissions
- S3 bucket for Lambda package storage

### **Deployment Commands**

```bash
# Navigate to infrastructure directory
cd infra/website-forms/

# Create new stack
./deploy-stack.sh --aws_profile assume --env dev --prefix mgcarclub --action create

# Update existing stack
./deploy-stack.sh --aws_profile assume --env dev --prefix mgcarclub --action update

# Delete stack (when needed)
aws cloudformation delete-stack --stack-name mgcarclub-website-forms --profile assume
```

### **Production Configuration**
The production deployment uses parameters from `params-prod.json`:
- **S3 Bucket**: `stackset-bcf-app-cicd-4e09c3e3-cf91-49b4-b3-bucket-ree4bfwucsfc`
- **Lambda Package**: `bosco-cloud-foundation.jamboree_register.prod.package`
- **Environment**: `prod`
- **Owner**: Craig Bosco (`craigbosco@mac.com`)

## 🔐 Security Configuration

### **API Key Setup**
1. Deploy the CloudFormation stack
2. Retrieve the API key from AWS Console → API Gateway → API Keys
3. Set `JAMBOREE_API_KEY` environment variable

### **Environment Variables**
The Lambda function requires:
- `TABLE_NAME`: DynamoDB table name (auto-configured)
- `SNS_TOPIC_ARN`: SNS topic ARN (auto-configured)

### **IAM Permissions**
The system uses least-privilege IAM roles for:
- **Lambda execution**: DynamoDB write, SNS publish, CloudWatch logs
- **API Gateway**: Lambda invoke permissions
- **CloudWatch**: Log group access

## 🧪 Testing

### **API Testing Interface**
Access `docs/api_test_v2.html` for interactive API testing with:
- Form field validation
- Real-time API calls
- Response debugging
- Production/test environment toggle

### **Manual Testing**
```bash
# Test endpoint with curl
curl -X POST \
  "https://your-api-gateway-url/v1/register" \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{
    "firstName": "John",
    "lastName": "Doe", 
    "email": "john@example.com",
    "eventType": "carShow",
    "is_production": false
  }'
```

## 📊 Monitoring

### **CloudWatch Metrics**
- API Gateway request counts and latency
- Lambda execution duration and errors
- DynamoDB read/write capacity usage

### **CloudWatch Logs**
- API Gateway access logs
- Lambda execution logs with detailed debugging
- Error tracking and alerting

### **SNS Delivery Status**
- Email delivery confirmations
- Failed delivery notifications

## 🔄 Data Flow Example

1. **User submits form** on `jamboree_form.html`
2. **PayPal processes payment** (if applicable)
3. **Frontend sends POST** to API Gateway `/v1/register` endpoint
4. **API Gateway validates** API key and forwards to Lambda
5. **Lambda function**:
   - Validates required fields
   - Generates unique registration ID
   - Stores data in DynamoDB
   - Sends notification via SNS
   - Returns success response
6. **SNS delivers emails** to club leadership
7. **User receives** confirmation with registration ID

## 🛠️ Development Setup

### **Local Development**
1. Clone repository
2. Configure AWS credentials
3. Update `docs/secrets.js` with development API key
4. Test with `docs/api_test_v2.html`

### **Infrastructure Changes**
1. Modify CloudFormation templates in `infra/website-forms/`
2. Test changes in development environment
3. Deploy to production using deployment script

## 📝 Environment Variables

### **Required for Frontend**
```javascript
// In docs/secrets.js or environment
JAMBOREE_API_KEY=your-api-gateway-key
```

### **Auto-configured for Lambda**
```bash
TABLE_NAME=RegistrationTable          # DynamoDB table
SNS_TOPIC_ARN=arn:aws:sns:...         # SNS topic
SES_SOURCE_EMAIL=Test                 # Currently unused
```

## 🎯 Event-Specific Features

### **MG Jamboree 2025: Cars in Paradise**
- **Dual Event Support**: Car show and optional boat tour
- **Payment Tiers**: Different pricing for show-only vs. combo packages
- **Participant Tracking**: Separate counts for car show attendees and boat tour participants
- **Vehicle Registry**: Year/Make/Model information for classic car documentation
- **Waiver Management**: Digital signature collection for liability protection

---

**Maintained by**: Craig Bosco (`craigbosco@mac.com`)  
**Version**: 0.1  
**Last Updated**: May 2025