# .NET CLI First Strategy for GitHub Actions

## ❌ **Problem**
```
📂 Framework path: C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.X
error CS0006: Metadata file 'C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.X\System.Windows.Forms.dll' could not be found
```

## 🔍 **Root Cause Analysis**

### **1. .NET Framework Version Detection Issue**
```powershell
# PROBLEM: $LatestFramework.Name returns unexpected format
$LatestFramework = Get-ChildItem $NetFxPath | Select-Object -First 1
# Result: "v4.X" instead of "v4.8"
```

### **2. Reference Assembly Path Issues**
```powershell
# PROBLEM: Reference Assemblies nicht in erwarteten Pfaden
C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.8\System.Windows.Forms.dll
# May not exist or be in different location in GitHub Actions
```

### **3. Complexity of Manual Reference Resolution**
- Multiple possible .NET Framework versions
- Different paths in different environments
- Complex reference assembly detection

## ✅ **Solution: .NET CLI First Strategy**

### **New Approach: Prefer .NET CLI**
```powershell
# PRIMARY: Use .NET CLI (most reliable)
if (Get-Command dotnet -ErrorAction SilentlyContinue) {
  Write-Host "✅ .NET CLI available - using as primary compiler"
  echo "USE_DOTNET_CLI=true" >> $env:GITHUB_ENV
}

# FALLBACK: Manual csc.exe with improved detection
else {
  # Enhanced .NET Framework detection with validation
}
```

## 🔧 **Implementation Details**

### **1. .NET CLI Compilation (.csproj approach)**
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net48</TargetFramework>
    <UseWindowsForms>true</UseWindowsForms>
    <AssemblyName>Setup</AssemblyName>
  </PropertyGroup>
  <ItemGroup>
    <Reference Include="Microsoft.Win32.Registry" />
  </ItemGroup>
  <ItemGroup>
    <Compile Include="build-tools/WIMaster-Setup.cs" />
  </ItemGroup>
</Project>
```

### **2. Enhanced .NET Framework Detection**
```powershell
# Improved framework detection with validation
$NetFxPath = "${env:ProgramFiles(x86)}\Reference Assemblies\Microsoft\Framework\.NETFramework"

if (Test-Path $NetFxPath) {
  $AvailableFrameworks = Get-ChildItem $NetFxPath | Where-Object {$_.Name -match "^v4\."} | Sort-Object Name -Descending
  Write-Host "📋 Available frameworks: $($AvailableFrameworks.Name -join ', ')"
  
  $LatestFramework = $AvailableFrameworks | Select-Object -First 1
  $FrameworkPath = $LatestFramework.FullName
  
  # VALIDATION: Verify assemblies exist
  $WinFormsPath = "$FrameworkPath\System.Windows.Forms.dll"
  if (-not (Test-Path $WinFormsPath)) {
    throw "Required .NET Framework assembly not found"
  }
}
```

### **3. Robust Reference Resolution**
```powershell
# Multiple search locations for assemblies
$PossibleRegistryPaths = @(
  "$FrameworkPath\Facades\Microsoft.Win32.Registry.dll",
  "$FrameworkPath\Microsoft.Win32.Registry.dll", 
  "${env:ProgramFiles}\dotnet\shared\Microsoft.NETCore.App\*\Microsoft.Win32.Registry.dll"
)

foreach ($Path in $PossibleRegistryPaths) {
  $ResolvedPaths = Resolve-Path $Path -ErrorAction SilentlyContinue
  if ($ResolvedPaths) {
    $RegistryDll = $ResolvedPaths[0].Path
    break
  }
}
```

## 📋 **Advantages of .NET CLI First**

| Aspect | Manual csc.exe | .NET CLI |
|--------|----------------|----------|
| **Reference Resolution** | ❌ Manual paths | ✅ Automatic |
| **Framework Detection** | ❌ Complex logic | ✅ SDK handles it |
| **Cross-Platform** | ❌ Windows only | ✅ Cross-platform |
| **Maintenance** | ❌ High | ✅ Low |
| **Reliability** | ❌ Environment dependent | ✅ Consistent |
| **Error Handling** | ❌ Complex | ✅ Simple |

## 🎯 **Expected GitHub Actions Output**

### **Successful .NET CLI Path:**
```
🔍 Searching for C# compiler...
✅ Found C# compiler: C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\Roslyn\csc.exe
✅ .NET CLI available - using as primary compiler

🔨 Compiling Setup.exe...
Using .NET CLI for compilation...
MSBuild version 17.8.5+b5265ef4f for .NET Framework
  Setup -> C:\actions-runner\_work\WIMaster\WIMaster\Setup.exe
✅ Setup.exe successfully compiled!
📁 File size: 15360 bytes
```

### **Fallback Manual csc.exe Path:**
```
🔍 Searching for C# compiler...
✅ Found C# compiler: C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\Roslyn\csc.exe
❌ .NET CLI not available

🔍 Searching for .NET Framework in: C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework
📋 Available frameworks: v4.8, v4.7.2, v4.7.1
📚 Using .NET Framework: v4.8
📂 Framework path: C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.8
✅ Found System.Windows.Forms.dll
📦 Found Registry DLL: C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.8\Facades\Microsoft.Win32.Registry.dll

🔨 Compiling Setup.exe...
Command: C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\Roslyn\csc.exe /win32icon:"WIMaster_Ico.ico" /target:winexe /platform:anycpu /optimize+ /reference:"C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.8\System.Windows.Forms.dll" /reference:"C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.8\Facades\Microsoft.Win32.Registry.dll" /out:Setup.exe build-tools/WIMaster-Setup.cs
✅ Setup.exe successfully compiled!
```

## 🔧 **Benefits of This Strategy**

### **1. Reliability**
- ✅ .NET CLI handles all reference resolution automatically
- ✅ No manual path detection needed
- ✅ Consistent across different GitHub Actions runners

### **2. Simplicity**
- ✅ Single .csproj file defines all dependencies
- ✅ Standard MSBuild process
- ✅ Familiar to .NET developers

### **3. Maintainability**
- ✅ Less custom PowerShell logic
- ✅ Standard .NET build process
- ✅ Future-proof with .NET updates

### **4. Error Handling**
- ✅ Clear MSBuild error messages
- ✅ Standard .NET error codes
- ✅ Better debugging information

## 🎉 **Result**

**The .NET CLI First Strategy solves:**

- ✅ **Complex Reference Resolution** - Automatic via MSBuild
- ✅ **Framework Version Detection** - Handled by SDK
- ✅ **Path Issues** - No manual path construction
- ✅ **Cross-Environment Compatibility** - Works everywhere .NET CLI works
- ✅ **Future-Proof** - Scales with .NET updates

---

**Setup.exe compilation is now reliable and maintainable! 🚀**
