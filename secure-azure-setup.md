# 🔐 Secure Azure Setup Guide (No Credentials in GitHub)

## **Option 1: Azure AD Managed Identity (Most Secure)**

### **Step 1: Create Azure AD App Registration**
1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Azure Active Directory** > **App registrations**
3. Click **"New registration"**
4. **Name**: `financial-ai-github-actions`
5. **Supported account types**: `Accounts in this organizational directory only`
6. Click **"Register"**

### **Step 2: Create Client Secret**
1. In your app registration, go to **"Certificates & secrets"**
2. Click **"New client secret"**
3. **Description**: `GitHub Actions Secret`
4. **Expires**: Choose appropriate duration
5. Click **"Add"**
6. **Copy the secret value immediately** (you won't see it again!)

### **Step 3: Get Required Values**
From your app registration, copy these values:
- **Application (client) ID**
- **Directory (tenant) ID**
- **Client secret** (from Step 2)
- **Subscription ID** (from Azure Portal > Subscriptions)

### **Step 4: Grant Permissions**
1. Go to your **Resource Group** (`financial-ai-rg`)
2. Click **"Access control (IAM)"**
3. Click **"Add"** > **"Add role assignment"**
4. **Role**: `Contributor`
5. **Assign access to**: `User, group, or service principal`
6. **Select**: Search for `financial-ai-github-actions`
7. Click **"Review + assign"**

### **Step 5: Add Minimal GitHub Secrets**
In your GitHub repository > Settings > Secrets and variables > Actions:

```
AZURE_CLIENT_ID = your-application-client-id
AZURE_TENANT_ID = your-directory-tenant-id  
AZURE_SUBSCRIPTION_ID = your-subscription-id
AZURE_CLIENT_SECRET = your-client-secret-value
```

### **Step 6: Update GitHub Actions**
Your workflow is already updated to use these secure values!

---

## **Option 2: Azure Key Vault Integration**

### **Step 1: Create Azure Key Vault**
1. In Azure Portal, create **Key Vault**
2. **Name**: `financial-ai-keyvault`
3. **Resource group**: `financial-ai-rg`
4. **Region**: `East US 2`

### **Step 2: Store Secrets in Key Vault**
Add these secrets to your Key Vault:
- `azure-openai-endpoint`
- `azure-openai-api-key`
- `langsmith-api-key`

### **Step 3: Enable Managed Identity**
1. Go to your Web Apps (staging & production)
2. **Settings** > **Identity**
3. **System assigned**: **On**
4. **Save**

### **Step 4: Grant Key Vault Access**
1. In Key Vault > **Access policies**
2. Click **"Add Access Policy"**
3. **Secret permissions**: `Get`
4. **Principal**: Select your Web App's managed identity
5. **Add** > **Save**

---

## **Option 3: Environment-Based Configuration**

### **Step 1: Use Azure App Configuration**
1. Create **App Configuration** resource
2. Store all your settings there
3. Access from your application using managed identity

### **Step 2: Application Settings Only**
Only store non-sensitive settings in GitHub:
- Deployment names
- Resource names
- Configuration flags

Store sensitive data in:
- Azure Key Vault
- App Configuration
- Managed Identity

---

## **🔧 Minimal GitHub Secrets Required**

With the updated workflow, you only need these 4 secrets:

```
AZURE_CLIENT_ID
AZURE_TENANT_ID  
AZURE_SUBSCRIPTION_ID
AZURE_CLIENT_SECRET
```

**All other sensitive data (API keys, endpoints) should be stored in Azure Key Vault!**

---

## **🚀 Deployment Steps**

1. **Create Azure AD App Registration** (Option 1)
2. **Set up Azure resources** (Resource Group, ACR, Web Apps)
3. **Add 4 GitHub secrets** (client ID, tenant ID, subscription ID, client secret)
4. **Push to GitHub** → Automatic deployment

## **✅ Security Benefits**

- ✅ **No sensitive credentials in GitHub**
- ✅ **Role-based access control**
- ✅ **Managed identity for Azure resources**
- ✅ **Secrets stored in Azure Key Vault**
- ✅ **Least privilege principle**

## **🔄 Alternative: GitHub Self-Hosted Runners**

For maximum security, run GitHub Actions on your Azure VM:

1. **Create self-hosted runner** on your Azure VM
2. **Use Azure CLI** with managed identity
3. **No secrets needed in GitHub**

---

**Recommendation: Use Option 1 (Azure AD App Registration) for the best balance of security and simplicity!**
