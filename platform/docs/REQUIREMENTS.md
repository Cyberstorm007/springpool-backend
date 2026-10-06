# SPRINGPOOL ENTERPRISE ERP / CRM / BUSINESS OPERATING PLATFORM

## MASTER PRODUCT REQUIREMENT

Build a production-grade, enterprise-level digital platform for **SpringPool**, an aquaculture feed, aqua-health, nutrition and related products company.

This must NOT be a simple website, dashboard template, CRUD application or prototype.

Build a complete enterprise business operating system combining:

- Corporate website
- ERP
- CRM
- Dealer/distributor portal
- Customer portal
- Sales management
- Lead management
- Order management
- Quotation management
- GST-ready invoicing
- Digital invoice signing
- Payments and receivables
- Inventory
- Warehouse management
- Production management
- Procurement
- Supplier management
- Logistics
- Employee management
- Task management
- Business intelligence
- Deterministic analytics
- Forecasting
- Business signals
- Automated alerts
- Management reporting
- WhatsApp Business integration
- Document management
- Audit/compliance
- Enterprise security

The product must feel like a serious MNC-grade enterprise platform inspired by the usability and discipline of systems such as SAP, Salesforce, Microsoft Dynamics and Oracle, while retaining a unique premium SpringPool identity.

Do not copy their branding or UI.

---

# 1. CORE TECHNOLOGY STACK

## Frontend

Use:

- Next.js latest stable
- TypeScript
- React
- Tailwind CSS
- shadcn/ui or equivalent enterprise-grade component system
- Responsive design
- PWA-ready architecture
- Accessible UI
- Dark/light mode
- Enterprise data tables
- Charts
- Command palette
- Global search
- Notifications
- File upload interfaces
- Drag-and-drop where useful
- Keyboard shortcuts

Use strict TypeScript.

Do not use unnecessary dependencies.

---

# 2. BACKEND

Use:

- Next.js server-side architecture
- TypeScript
- Supabase
- PostgreSQL
- Supabase Auth
- Supabase Storage
- Supabase Realtime
- Supabase Edge Functions where appropriate

Business logic must run server-side.

Never trust the browser for:

- permissions
- pricing
- GST calculations
- inventory calculations
- invoice totals
- credit limits
- financial calculations
- order approval
- digital signing

---

# 3. INFRASTRUCTURE

Use:

Cloudflare
+
GitHub
+
Supabase

Architecture:

User
↓
Cloudflare
↓
Next.js Application
↓
Supabase
├── PostgreSQL
├── Auth
├── Storage
├── Realtime
└── Edge Functions

External integrations:

Meta WhatsApp Business Platform
Future payment gateway
Future logistics providers
Future GST/e-invoice integrations
Future AI layer

---

# 4. CLOUDFLARE

Configure the platform for Cloudflare.

Use:

- Cloudflare DNS
- SSL/TLS
- WAF
- CDN
- Turnstile
- rate limiting
- bot protection
- security headers
- caching where appropriate

Use secure production configuration.

Do not expose:

- Supabase service-role key
- database credentials
- WhatsApp access tokens
- webhook secrets
- signing credentials
- future API credentials

All secrets must use environment variables or secure secret storage.

---

# 5. ENVIRONMENTS

Create separate:

development
staging
production

Do not mix production credentials with development.

Create:

.env.example

Never commit actual credentials.

---

# 6. GITHUB

Use GitHub as the source-control repository.

Create:

.github/workflows/

Implement CI/CD for:

- lint
- type checking
- tests
- security checks
- production build
- deployment

Pull requests should be validated before deployment.

---

# 7. APPLICATION STRUCTURE

Create:

/app
/components
/lib
/services
/hooks
/types
/utils
/config
/database
/supabase
/public
/docs
/tests

Organize business services independently.

Example:

/lib/services/orders
/lib/services/inventory
/lib/services/invoices
/lib/services/customers
/lib/services/dealers
/lib/services/production
/lib/services/finance
/lib/services/analytics
/lib/services/whatsapp

Keep business logic separate from UI components.

---

# 8. ROUTING

Create:

/
/about
/products
/aquaculture
/quality
/sustainability
/contact
/careers

ERP:

/dashboard
/crm
/leads
/customers
/dealers
/products
/orders
/quotations
/invoices
/payments
/inventory
/warehouses
/production
/procurement
/suppliers
/logistics
/finance
/employees
/tasks
/analytics
/alerts
/reports
/communications
/whatsapp
/documents
/audit
/settings

Dealer:

/dealer
/dealer/catalog
/dealer/orders
/dealer/invoices
/dealer/payments
/dealer/account
/dealer/support

Customer:

/customer
/customer/orders
/customer/invoices
/customer/account
/customer/support

---

# 9. AUTHENTICATION

Use Supabase Auth.

Support:

- email/password
- secure password reset
- email verification
- session management
- optional MFA
- account lockout/rate limiting
- secure cookies
- login activity

Do not implement authentication manually.

---

# 10. RBAC

Implement enterprise-grade Role-Based Access Control.

Roles:

SUPER_ADMIN
DIRECTOR
ADMIN
SALES_MANAGER
SALES_EXECUTIVE
DEALER_MANAGER
DEALER
DISTRIBUTOR
ACCOUNTANT
FINANCE_MANAGER
PRODUCTION_MANAGER
PRODUCTION_EMPLOYEE
WAREHOUSE_MANAGER
WAREHOUSE_EMPLOYEE
PROCUREMENT_MANAGER
HR_MANAGER
EMPLOYEE
CUSTOMER
INVESTOR

Also implement granular permissions.

Examples:

users.view
users.create
users.edit
users.delete

customers.view
customers.create
customers.edit

orders.view
orders.create
orders.approve
orders.cancel

inventory.view
inventory.adjust

invoice.create
invoice.approve
invoice.issue
invoice.sign
invoice.cancel

finance.view
finance.approve

reports.view
reports.export

whatsapp.view
whatsapp.send

Every permission must be enforced server-side.

---

# 11. SUPABASE ROW LEVEL SECURITY

Use PostgreSQL RLS on sensitive tables.

Examples:

A dealer can access ONLY:

- their account
- their contacts
- their orders
- their invoices
- their payments
- their documents

A salesperson can access assigned customers/orders unless granted wider permissions.

Employees cannot automatically access finance.

Customers cannot access dealer data.

Users cannot bypass restrictions through API calls.

Test RLS independently.

---

# 12. DATABASE

Use PostgreSQL with UUID primary keys.

Core tables:

organizations
company_settings
users
roles
permissions
user_roles
customers
customer_contacts
dealers
distributors
employees
addresses
leads
lead_activities
products
product_categories
product_variants
product_prices
price_lists
warehouses
warehouse_locations
inventory
inventory_movements
stock_batches
stock_reservations
suppliers
purchase_requisitions
purchase_orders
purchase_order_items
goods_receipts
sales_orders
sales_order_items
quotations
quotation_items
invoices
invoice_items
credit_notes
debit_notes
payments
payment_allocations
accounts
ledger_entries
tax_rates
production_plans
production_batches
production_inputs
production_outputs
quality_checks
shipments
delivery_tracking
tasks
notifications
documents
whatsapp_contacts
whatsapp_conversations
whatsapp_messages
whatsapp_templates
analytics_metrics
business_signals
alert_rules
alert_events
forecast_results
audit_logs

Every appropriate record should contain:

created_at
updated_at
created_by
updated_by

Use:

foreign keys
constraints
indexes
unique constraints
transactions

Use soft deletion where appropriate.

---

# 13. COMPANY PROFILE

Create:

Settings → Company Profile

Fields:

legal company name
display name
logo
address
registered office
GSTIN
PAN
CIN where applicable
phone
email
website
bank details
financial year
invoice prefix
authorized signatories

Never hardcode company information into frontend code.

---

# 14. PRODUCT MANAGEMENT

Build a flexible product catalog.

Categories include:

AQUA FEED

- Vannamei shrimp feed
- Tiger shrimp feed
- Fish feed

AQUA HEALTH

- Aqua medicines
- Minerals
- Probiotics
- Vitamins
- Water-treatment products

Allow future categories.

Product fields:

name
SKU
category
brand
description
technical specifications
packaging
weight
unit
HSN/SAC
GST rate
MRP
dealer price
distributor price
special price
cost
minimum stock
reorder point
lead time
images
documents
active status

Never hardcode prices or tax rates.

---

# 15. CRM

Build a full CRM.

Lead pipeline:

NEW
CONTACTED
QUALIFIED
PROPOSAL
NEGOTIATION
CONVERTED
LOST

Track:

lead source
customer
contact
phone
WhatsApp
email
location
farm size
aquaculture type
species
estimated requirement
expected order value
salesperson
next follow-up
notes
attachments
communication history

Views:

- table
- Kanban
- pipeline
- analytics

---

# 16. CUSTOMER MANAGEMENT

Customer profile should contain:

company/person name
contact details
addresses
GSTIN
PAN
customer type
assigned salesperson
purchase history
order history
invoice history
payment history
outstanding
credit limit
documents
communications
notes
activity timeline

Show automatically calculated:

lifetime value
average order value
purchase frequency
last purchase
days since purchase
sales trend
payment behavior

---

# 17. DEALER MANAGEMENT

Dealer profile:

dealer ID
legal name
contacts
territory
salesperson
pricing tier
credit limit
payment terms
outstanding balance
order history
invoice history
sales trend
documents
contracts
communications

Dealer dashboard:

- sales
- orders
- outstanding
- available credit
- recent invoices
- reorder products
- alerts

Dealers cannot access another dealer's information.

---

# 18. DEALER PORTAL

Dealer can:

- log in
- browse products
- see authorized pricing
- check stock availability
- create order
- reorder
- view orders
- view invoices
- download invoices
- see outstanding balance
- upload payment proof
- contact SpringPool
- raise support requests
- receive WhatsApp notifications

---

# 19. QUOTATIONS

Build quotation management.

Quotation states:

DRAFT
SENT
UNDER_NEGOTIATION
ACCEPTED
REJECTED
EXPIRED
CONVERTED

Generate professional SpringPool quotation PDFs.

Quotation can convert directly into:

Sales Order

Do not require retyping data.

---

# 20. ORDER MANAGEMENT

Order workflow:

DRAFT
→ SUBMITTED
→ SALES_REVIEW
→ CREDIT_CHECK
→ APPROVED
→ INVENTORY_CHECK
→ ALLOCATED
→ PACKED
→ DISPATCHED
→ DELIVERED
→ COMPLETED

Support:

- manual order
- dealer order
- distributor order
- salesperson order
- WhatsApp-originated order
- repeat order
- bulk order

Generate:

SP-ORD-2026-000001

Every status transition must be audited.

---

# 21. ORDER VALIDATION

Before order approval:

Check:

customer validity
product validity
price authorization
stock
credit limit
outstanding amount
payment terms
GST details
shipping address

Do not allow unauthorized discounts.

---

# 22. INVENTORY

Implement real inventory accounting.

Formula:

Opening Stock
+
Purchases
+
Production
+
Transfers In
-
Sales
-
Consumption
-
Transfers Out
-
Damages
± Adjustments
=
Closing Stock

Never directly modify stock balances.

Every change creates:

inventory_movement

Types:

PURCHASE
SALE
PRODUCTION
CONSUMPTION
TRANSFER
DAMAGE
RETURN
ADJUSTMENT

Support:

- multiple warehouses
- locations
- batches
- expiry
- stock reservation
- stock transfers
- stock reconciliation
- valuation
- traceability

---

# 23. PRODUCTION

Build production management.

Workflow:

Production Plan
→ Raw Material Allocation
→ Batch Creation
→ Manufacturing
→ QC
→ Finished Goods
→ Warehouse

Track:

BOM
formulation
raw materials
quantity
production batch
input quantity
output quantity
wastage
labour
energy
packaging
production cost
machine utilization
QC results

Calculate:

cost/kg
cost/tonne
batch cost
yield
wastage
efficiency
capacity utilization

---

# 24. PROCUREMENT

Workflow:

Purchase Requisition
→ Approval
→ RFQ
→ Supplier Selection
→ Purchase Order
→ Goods Receipt
→ Quality Check
→ Inventory
→ Supplier Invoice

Track:

supplier price
lead time
delivery performance
quality
rejection
purchase volume

---

# 25. FINANCE

Implement:

sales
purchases
receivables
payables
payments
expenses
credit limits
payment allocations
financial summaries

Dashboards:

Revenue
Gross Profit
Gross Margin
Receivables
Payables
Inventory Value
Cash-related operational metrics
Sales by Product
Sales by Dealer
Sales by Region

Do not claim full statutory accounting functionality unless properly implemented.

---

# 26. GST-READY INVOICING

Create server-side GST calculations.

Support:

CGST
SGST
IGST
Cess where applicable
discounts
rounding
tax-inclusive pricing

Store:

taxable amount
CGST
SGST
IGST
cess
round-off
grand total

Recalculate everything on the backend.

---

# 27. SPRINGPOOL BRANDED INVOICES

Every invoice must use the official SpringPool header.

Include:

SpringPool logo
legal name
registered address
GSTIN
PAN
CIN where applicable
phone
email
website

Invoice:

invoice number
invoice date
due date
place of supply
reverse charge status
payment terms

Buyer:

name
address
GSTIN
PAN where applicable
contact information

Items:

Sr No
Product
SKU
HSN/SAC
Batch
Quantity
Unit
Rate
Discount
Taxable Value
GST %
Tax Amount
Total

Tax summary:

Taxable Amount
CGST
SGST
IGST
Cess
Round-off
Grand Total

Payment information:

Bank
Account Name
Account Number
IFSC
UPI where applicable
Payment Terms

Footer:

Terms
Authorized signatory
Digital signature status
Verification information

---

# 28. INVOICE NUMBERING

Use configurable numbering.

Example:

SP/INV/2026-27/000001

Support:

prefix
financial year
branch
business unit
sequence

Invoice number must be unique.

Issued invoice numbers cannot silently be reused.

---

# 29. INVOICE STATES

DRAFT
PENDING_APPROVAL
APPROVED
ISSUED
SENT
PARTIALLY_PAID
PAID
CANCELLED
VOID

Issued invoices cannot simply be edited.

Use cancellation/credit-note workflows.

---

# 30. PDF INVOICE GENERATION

Generate professional A4 PDF server-side.

Requirements:

- SpringPool header
- logo
- page numbering
- repeating item headers
- GST summary
- currency formatting
- authorized signatory
- digital signature area
- QR verification code where configured

Never use screenshots as invoice PDFs.

---

# 31. DIGITAL SIGNATURE

Support proper certificate-based digital signing.

IMPORTANT:

A signature image is NOT a cryptographic digital signature.

Architecture:

Invoice
↓
Validated PDF
↓
Digital signing service
↓
Cryptographically signed PDF
↓
Hash
↓
Secure storage

Never mark an invoice "Digitally Signed" if only a visual signature image exists.

If no signing certificate/provider is configured:

DIGITAL SIGNATURE PENDING

---

# 32. DIGITAL SIGNATURE SETTINGS

Create:

Settings
→ Finance
→ Digital Signature

Support:

authorized signatory
certificate/provider
certificate expiry
signing reason
signing location
timestamping where supported
signature appearance
signature placement

Private signing credentials must never reach the browser.

Prefer secure certificate/signing infrastructure.

---

# 33. INVOICE HASH

Generate SHA-256 hash for final invoice documents.

Store:

document_hash
signature_status
signed_at
signed_by
storage_path

Use this to detect document tampering.

---

# 34. INVOICE VERIFICATION

Every invoice receives a verification ID.

Example:

SPV-8F4A92XXXX

Generate QR code.

Verification URL:

/verify/invoice/[verificationId]

Public verification should show only appropriate information:

invoice number
date
seller
buyer where appropriate
total
tax
status
digital-signature status

Do not expose private customer information.

---

# 35. CREDIT NOTES / DEBIT NOTES

Support:

Credit Notes
Debit Notes

Link them to original invoices.

Never modify historical financial records directly.

---

# 36. PAYMENTS

Track:

payment date
amount
mode
reference
bank
customer
dealer
invoice allocation
receipt

Statuses:

UNALLOCATED
PARTIALLY_ALLOCATED
ALLOCATED

Automatically update invoice balances.

---

# 37. WHATSAPP BUSINESS

Integrate the official Meta WhatsApp Business Platform/Cloud API.

Architecture:

SpringPool ERP
↓
WhatsApp integration service
↓
Meta WhatsApp Cloud API
↓
Customer WhatsApp

Support:

incoming messages
outgoing messages
text
images
documents
invoice PDFs
order confirmations
shipment updates
payment reminders
customer support
sales communication
approved templates

---

# 38. WHATSAPP CRM

Every WhatsApp contact should map to:

customer
dealer
lead
or prospect

Store:

whatsapp_contacts
whatsapp_conversations
whatsapp_messages

Show WhatsApp communication history inside CRM profiles.

---

# 39. WHATSAPP ORDERING

Implement deterministic WhatsApp ordering.

Example:

Customer:

"Send 20 bags Vannamei feed 1.2mm."

System:

1. identify phone number
2. identify customer
3. identify product
4. identify SKU
5. check stock
6. retrieve authorized price
7. check credit
8. create draft order
9. request confirmation
10. finalize after confirmation
11. generate order number
12. notify salesperson

No AI is required.

If message is ambiguous:

→ route to human employee.

---

# 40. WHATSAPP INVOICES

When an invoice reaches ISSUED state:

Invoice
→ Generate PDF
→ Digitally sign where configured
→ Store securely
→ Generate secure access link
→ Send through approved WhatsApp mechanism

Never send an unissued invoice as a final invoice.

---

# 41. BUSINESS INTELLIGENCE

Create a native deterministic Business Intelligence Engine.

This is NOT AI.

Do not use:

- OpenAI
- ChatGPT
- LLMs
- machine-learning APIs
- AI agents

All calculations must originate from SpringPool ERP data.

---

# 42. SALES ANALYTICS

Calculate:

gross sales
net sales
sales returns
growth %
target achievement
average order value
orders/customer
revenue/dealer
revenue/salesperson
revenue/product
revenue/category
revenue/region
month-on-month growth
year-on-year growth
sales velocity
repeat order rate

Compare:

current period
previous period
same period last year

---

# 43. CRM ANALYTICS

Calculate:

lead count
qualified leads
conversion rate
lead aging
conversion time
pipeline value
weighted pipeline
salesperson performance
overdue follow-ups
dormant leads
lead-to-order conversion

Signals:

FOLLOW_UP_OVERDUE
STAGNANT_LEAD
LOW_CONVERSION
PIPELINE_RISK

---

# 44. CUSTOMER ANALYTICS

Calculate:

lifetime sales
current sales
previous sales
average order value
purchase frequency
last order
days since order
total orders
returns
payment behavior
outstanding
credit utilization
purchase trend

Statuses:

ACTIVE
GROWING
STABLE
DECLINING
DORMANT
AT_RISK

Use transparent deterministic rules.

---

# 45. DEALER RISK ENGINE

Create dealer health scoring.

Factors:

sales trend
payment behavior
outstanding exposure
credit utilization
order frequency
returns
activity

Example configurable weighting:

Sales trend: 25%
Payment behavior: 25%
Outstanding exposure: 20%
Order frequency: 15%
Returns/cancellations: 10%
Activity: 5%

Display:

Dealer Health Score: X/100

And explain:

- sales declined X%
- outstanding increased X%
- no order for X days
- overdue amount ₹X

Never hide the calculation.

---

# 46. INVENTORY ANALYTICS

Calculate:

current stock
available stock
reserved stock
incoming stock
reorder point
safety stock
stock turnover
inventory days
dead stock
slow-moving stock
fast-moving stock
stockout frequency
inventory value
expiry risk

Signals:

LOW_STOCK
STOCKOUT_RISK
OVERSTOCK
DEAD_STOCK
SLOW_MOVING
EXPIRING_BATCH

---

# 47. DEMAND FORECASTING

Implement statistical forecasting.

Methods:

moving average
weighted moving average
exponential smoothing
seasonal averages where sufficient data exists

Forecast:

product demand
SKU demand
dealer demand
regional demand
weekly demand
monthly demand

Display:

historical demand
forecast
forecast horizon
method used
accuracy/error metrics when sufficient data exists

Clearly distinguish forecast from actual.

---

# 48. SALES FORECASTING

Calculate:

monthly projected revenue
quarterly projected revenue
annual projected revenue
expected orders
expected volume
target achievement

Show:

ACTUAL
TARGET
FORECAST

Never mix them.

---

# 49. PAYMENT ANALYTICS

Calculate:

receivables
overdue receivables
aging
average collection period
collection rate
customer outstanding
dealer outstanding

Aging:

0–30
31–60
61–90
91–180
180+

Signals:

PAYMENT_DUE
PAYMENT_OVERDUE
HIGH_EXPOSURE
CREDIT_LIMIT_WARNING
CRITICAL_OVERDUE

---

# 50. PRODUCTION ANALYTICS

Calculate:

planned production
actual production
variance
capacity utilization
yield
raw material consumption
wastage
batch cost
cost/kg
cost/tonne
efficiency

Signals:

PRODUCTION_DELAY
HIGH_WASTAGE
LOW_YIELD
CAPACITY_CONSTRAINT
COST_VARIANCE

---

# 51. PROCUREMENT ANALYTICS

Calculate:

supplier lead time
purchase price trend
purchase quantity
delivery performance
rejection rate
price variance
purchase frequency

Signals:

SUPPLIER_DELAY
PRICE_INCREASE
QUALITY_ISSUE
PROCUREMENT_RISK

---

# 52. ANOMALY DETECTION

Use statistical/rule-based detection.

Examples:

unusually large order
unusual discount
sales spike
sales decline
unexpected inventory reduction
unusual payment delay
abnormal wastage
purchase price anomaly
unusual return rate

Methods:

mean
median
standard deviation
rolling averages
percentage deviation
IQR
configurable thresholds

Every anomaly shows:

metric
observed value
expected value
deviation
method
timestamp

---

# 53. BUSINESS SIGNAL ENGINE

Create centralized:

business_signals

Fields:

id
type
severity
entity_type
entity_id
metric
observed_value
expected_value
threshold
message
reason
created_at
resolved_at
status

Severity:

INFO
LOW
MEDIUM
HIGH
CRITICAL

---

# 54. ALERT CENTER

Create:

/alerts

Show:

Critical
High
Medium
Low
Resolved

Actions:

acknowledge
assign
resolve
snooze
comment

Maintain audit trail.

---

# 55. ALERT RULES

Create:

/settings/business-rules

Admins can configure:

reorder point
minimum stock
overdue threshold
credit threshold
sales decline %
anomaly threshold
forecast method
forecast horizon
dealer risk weights
customer inactivity
lead inactivity
production variance
wastage threshold

Every configuration change must be audited.

---

# 56. AUTOMATIC MANAGEMENT SUMMARY

Create management dashboards based entirely on real calculations.

Sections:

Executive KPIs
Sales
Orders
Customers
Dealers
Inventory
Production
Procurement
Receivables
Payables
Alerts
Forecasts

Example:

SALES
Revenue increased 14.2%.

INVENTORY
3 SKUs below reorder point.

RECEIVABLES
₹X outstanding.

DEALERS
5 dealers showing declining purchase trends.

PRODUCTION
Capacity utilization X%.

All values must originate from database calculations.

No AI-generated prose.

---

# 57. SCHEDULED ANALYTICS

Use scheduled/background jobs.

Every 15 minutes:

critical inventory signals
urgent operational alerts

Hourly:

operational KPIs
inventory metrics
payment alerts

Daily:

sales analytics
dealer analytics
customer analytics
production analysis
anomaly detection

Weekly:

forecasting
trend analysis
management summaries

Monthly:

management reports
financial KPIs
dealer performance
product performance

Do not recalculate expensive historical analytics on every page load.

Use caching/materialized views where appropriate.

---

# 58. REPORTING

Generate:

Sales Report
Dealer Report
Customer Report
Inventory Report
Production Report
Purchase Report
Receivables Report
Payables Report
Profitability Report
GST Report
Order Report
Product Performance Report
Supplier Report
Employee Activity Report
WhatsApp Communication Report
Management Report

Support:

PDF
CSV

Respect permissions.

---

# 59. GLOBAL SEARCH

Search:

customers
dealers
orders
invoices
products
employees
suppliers
documents
WhatsApp conversations
leads
signals

Start with PostgreSQL full-text search.

Keep architecture extensible for dedicated search infrastructure later.

---

# 60. NOTIFICATION CENTER

Events:

New Lead
New Order
Order Approval
Low Stock
Stockout Risk
Payment Overdue
Production Completed
Shipment Dispatched
New WhatsApp Message
Invoice Generated
Dealer Registration
Critical Alert
Forecast Warning

Notifications must respect user permissions.

---

# 61. DOCUMENT MANAGEMENT

Store:

contracts
invoices
quotations
purchase orders
quality certificates
dealer documents
supplier documents
employee documents

Use private Supabase Storage buckets.

Generate signed URLs.

Never expose private documents publicly.

---

# 62. AUDIT SYSTEM

Record:

LOGIN
LOGOUT
LOGIN_FAILURE
CREATE
UPDATE
DELETE
APPROVE
REJECT
EXPORT
PASSWORD_CHANGE
ROLE_CHANGE
ORDER_STATUS_CHANGE
INVOICE_ISSUED
INVOICE_SIGNED
INVOICE_CANCELLED
PAYMENT
INVENTORY_ADJUSTMENT
WHATSAPP_MESSAGE
BUSINESS_RULE_CHANGE

Each entry:

actor
action
entity
entity_id
timestamp
before
after
metadata

Audit logs must be tamper-resistant from normal users.

---

# 63. SECURITY

Implement:

- server-side authorization
- RLS
- input validation
- output encoding
- rate limiting
- secure cookies
- CSRF protection where applicable
- CSP
- security headers
- webhook verification
- secret isolation
- secure file handling
- upload validation
- MIME validation
- file-size limits
- audit logging
- backup strategy
- disaster recovery documentation

---

# 64. API

Create versioned APIs:

/api/v1/auth
/api/v1/customers
/api/v1/dealers
/api/v1/products
/api/v1/leads
/api/v1/orders
/api/v1/quotations
/api/v1/invoices
/api/v1/payments
/api/v1/inventory
/api/v1/production
/api/v1/procurement
/api/v1/finance
/api/v1/analytics
/api/v1/signals
/api/v1/reports
/api/v1/whatsapp

Response format:

{
  "success": true,
  "data": {},
  "error": null,
  "requestId": "..."
}

Use schema validation for every endpoint.

---

# 65. IDEMPOTENCY

Critical operations must be idempotent.

Especially:

orders
payments
invoice issuance
WhatsApp webhooks
inventory movements
digital signing

Repeated requests must not create duplicate financial records.

---

# 66. TRANSACTIONS

Use database transactions for multi-step operations.

Examples:

Order approval:

validate
→ reserve stock
→ validate credit
→ update order
→ create inventory reservation
→ create audit record

Invoice:

validate order
→ calculate GST
→ create invoice
→ assign number
→ commit
→ generate PDF
→ sign
→ store

---

# 67. PUBLIC CORPORATE WEBSITE

Create premium SpringPool website.

Pages:

Home
About
Products
Aquaculture Solutions
Technology
Quality
Sustainability
Dealer Network
Contact
Careers

Design:

premium
corporate
technical
clean
modern
credible

Avoid:

generic templates
excessive gradients
cheap-looking animations
fake statistics
placeholder business claims

---

# 68. DESIGN SYSTEM

SpringPool UI should have:

strong typography
clear hierarchy
spacious layout
professional tables
premium cards
clear statuses
subtle animation
responsive navigation
consistent spacing
consistent iconography

Dashboard should feel like a corporate command center.

---

# 69. MOBILE

ERP must work on mobile for:

salespeople
warehouse employees
dealers
management

Prioritize:

orders
customers
inventory
alerts
WhatsApp
invoices
approvals

---

# 70. AI — EXPLICITLY DEFERRED

DO NOT integrate AI now.

Do NOT install:

OpenAI SDK
ChatGPT integration
LLM APIs
AI agents
MCP
AI chatbot
AI forecasting
AI-generated reports
AI recommendations

Do NOT request an OpenAI API key.

Do NOT send SpringPool business data to AI providers.

The ERP must be completely functional without AI.

---

# 71. FUTURE AI ARCHITECTURE

Design the system so AI can be added later.

Future architecture:

SpringPool ERP
↓
Deterministic Analytics Engine
↓
Business Signals
↓
Authorized Service Layer
↓
Future AI Layer

AI must never directly bypass:

RLS
RBAC
audit logs
business rules

AI will eventually be able to interpret already-calculated business information.

The underlying financial and operational calculations must always remain deterministic.

---

# 72. CHATGPT ACCOUNT

Do NOT connect the production ERP directly to a personal ChatGPT account.

Do not request ChatGPT passwords, cookies or sessions.

When AI is eventually introduced, use a secure enterprise API/service architecture.

For now, there is no AI dependency.

---

# 73. WHATSAPP COST ARCHITECTURE

Design WhatsApp as an independent integration service.

The application must continue working if WhatsApp is temporarily unavailable.

Queue outgoing messages.

Retry safely.

Track:

QUEUED
SENT
DELIVERED
READ
FAILED

Do not duplicate messages during retries.

Do not assume WhatsApp API messaging is permanently free.

---

# 74. ERROR HANDLING

Every major operation must have:

loading state
success state
empty state
error state
retry action

Never silently fail.

Display useful human-readable errors.

Log technical errors securely.

Do not expose database internals to users.

---

# 75. PERFORMANCE

Optimize for:

fast dashboard loading
pagination
database indexes
server-side filtering
server-side sorting
lazy loading
caching
materialized analytics
background calculations

Never load thousands of database rows into the browser unnecessarily.

---

# 76. OBSERVABILITY

Prepare:

structured application logs
request IDs
error tracking
audit logs
performance monitoring

Critical business transactions should be traceable from:

User
→ Request
→ API
→ Database transaction
→ Business result

---

# 77. TESTING

Create:

unit tests
integration tests
RLS tests
API tests
security tests
E2E tests

Test:

authentication
RBAC
dealer isolation
order creation
order approval
inventory
GST
invoice calculation
invoice numbering
digital-signature status
payments
analytics
alerts
forecasting
WhatsApp webhooks
WhatsApp retries
file security
audit logs

Include negative tests.

---

# 78. DATA INTEGRITY

Never use fake production data.

Development seed data must be clearly identified.

Production dashboards must show actual database values.

Never fabricate:

sales
customers
orders
inventory
profit
GST
payments
forecast results

---

# 79. DOCUMENTATION

Create:

README.md
ARCHITECTURE.md
DATABASE.md
SECURITY.md
DEPLOYMENT.md
API.md
WHATSAPP.md
INVOICING.md
DIGITAL-SIGNATURE.md
ANALYTICS.md
REPORTING.md
RLS.md
DISASTER-RECOVERY.md
FUTURE-AI.md

Document:

architecture
database
environment variables
deployment
security
permissions
business rules
analytics formulas
WhatsApp integration
invoice workflow
digital signature
future AI architecture

---

# 80. IMPLEMENTATION PHASES

Do NOT generate a fake complete system in one pass.

Build incrementally.

## PHASE 1 — FOUNDATION

- Next.js
- TypeScript
- Supabase
- Auth
- RBAC
- RLS
- Cloudflare
- GitHub
- base UI
- company settings
- audit system

## PHASE 2 — MASTER DATA

- products
- categories
- customers
- dealers
- suppliers
- employees
- warehouses

## PHASE 3 — SALES & CRM

- leads
- CRM
- quotations
- orders
- dealer portal
- customer portal

## PHASE 4 — INVENTORY

- inventory
- batches
- reservations
- transfers
- warehouse management

## PHASE 5 — PRODUCTION

- BOM
- production plans
- production batches
- QC
- production costs

## PHASE 6 — FINANCE

- invoices
- GST
- payments
- receivables
- credit notes
- debit notes

## PHASE 7 — DIGITAL DOCUMENTS

- branded PDF invoices
- PDF signing
- verification
- hashing
- document storage

## PHASE 8 — WHATSAPP

- Meta Cloud API
- webhook
- CRM integration
- order workflow
- invoice delivery
- notifications

## PHASE 9 — BUSINESS INTELLIGENCE

- analytics
- KPI engine
- forecasting
- dealer risk
- anomaly detection
- business signals
- alerts
- management reports

## PHASE 10 — HARDENING

- security audit
- RLS audit
- performance
- testing
- backups
- disaster recovery
- production deployment

---

# 81. FINAL QUALITY STANDARD

Before declaring the application complete:

Run:

npm run lint
npm run typecheck
npm test
npm run build

Also verify:

- database migrations
- RLS
- authentication
- authorization
- API security
- Cloudflare
- webhook security
- invoice calculations
- GST calculations
- invoice numbering
- digital-signature state
- inventory integrity
- financial integrity
- analytics calculations
- forecasting
- alert rules
- WhatsApp message handling
- document security
- audit logging
- mobile responsiveness

Fix all errors before completion.

---

# 82. NON-NEGOTIABLE PRINCIPLES

1. Security before convenience.
2. Database is the source of truth.
3. Backend is the authority.
4. Never trust frontend calculations.
5. Never bypass RLS.
6. Never expose secrets.
7. Never fabricate business data.
8. Never modify issued financial records silently.
9. Every inventory movement must be traceable.
10. Every financial operation must be auditable.
11. Every business signal must be explainable.
12. Every forecast must be clearly labeled as a forecast.
13. WhatsApp must be an integration, not a core dependency.
14. AI is NOT part of the current system.
15. The architecture must remain AI-ready for a future phase.
16. Critical operations must be transactional and idempotent.
17. The system must remain usable if an external integration fails.
18. Build real functionality rather than visual placeholders.
19. Prefer configurable business rules over hardcoded assumptions.
20. Design for SpringPool's growth from a small enterprise into an MNC-scale operation.

FINAL OBJECTIVE:

Create a secure, scalable, auditable, premium enterprise platform that becomes the central operating system for SpringPool's:

CRM
Sales
Dealers
Customers
Orders
Inventory
Production
Procurement
Finance
Invoices
Payments
Employees
Communications
Analytics
Business intelligence
Management reporting

The system must operate independently without AI.

Future AI should be an optional intelligence layer placed on top of a reliable, deterministic ERP foundation.