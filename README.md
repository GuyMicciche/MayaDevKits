# Autodesk Maya DevKits - Automated Plugin Compiling

Streamlined development and compilation of **C++**, **Qt**, **Python**, and **PyQt** plugins for Autodesk Maya across multiple versions (2020-2027).

## Maya API Update Guides
- [Maya devkit—What’s New / What’s Changed](https://help.autodesk.com/view/MAYADEV/2027/ENU/?guid=Maya_DEVHELP_Whats_New_Whats_Changed_html)
- [Maya 2027 API Update Guide](https://blog.autodesk.io/maya-2027-api-update-guide/)
- [Maya 2026 API Update Guide](https://blog.autodesk.io/maya-2026-api-update-guide/)
- [Maya 2025 API Update Guide](https://blog.autodesk.io/maya-2025-api-update-guide/)
- [Maya 2024 API Update Guide](https://blog.autodesk.io/maya-2024-api-update-guide/)
- [Maya 2023 API Update Guide](https://blog.autodesk.io/maya-2023-api-update-guide/)
- [Maya 2022 API Update Guide](https://blog.autodesk.io/maya-2022-api-update-guide/)
- [Maya 2020 API Update Guide](https://blog.autodesk.io/maya-2020-api-update-guide/)

## Prerequisites

### Required Software
1. **Visual Studio 2022** (any edition: Community, Professional, or Enterprise) [Download Visual Studio 2022](https://visualstudio.microsoft.com/downloads/)
   - During installation, ensure you select: **"Desktop development with C++"** workload
   - This includes the necessary MSVC compiler and Windows SDK components
   - CMake comes with VS2022, but you might want to download it and add it to your PATH environment variable [Download CMake Windows x64 Installer](https://cmake.org/download/)

2. **Autodesk Maya** (any supported version 2020-2027) [Download Maya](https://www.autodesk.com/products/maya/overview)
   - Required for testing your compiled plugins

## Getting Started

### Step 1: Download Maya DevKits

1. Visit the **official Maya Developer Center**: https://aps.autodesk.com/developer/overview/maya
2. Scroll to the bottom of the page to find the **DevKit packages**
3. Download the **Windows DevKit** for each Maya version you want to support
4. You'll need an Autodesk account (free registration) to access the downloads

### Step 2: Set Up DevKit Directory Structure

1. **Create a base directory** for all your Maya DevKits, for example:
   ```
   C:\MayaDevKits\
   ```

2. **Extract each downloaded zip file**:
   - Each zip contains a root folder named `devkitBase` - **ignore this folder**
   - Extract the **contents** of `devkitBase` directly into version-specific folders
   - For Maya 2027/2026/2025, you need to extract the included `Qt.zip` into the root folder
   - For Maya 2024/2023/2022/2020, there will be qt zip files inside the `cmake`, `include`, and `mkspecs` folders you need to extract them to compile plugins that use Qt.

3. **Your final structure should look like this**:
   ```
   C:\MayaDevKits\
   ├── 2020\ (Qt 5.12.3)
   │   ├── cmake\ (extract included qt-5.12.3_vc14-cmake.zip contents here)
   │   ├── devkit\
   │   ├── include\ (extract included qt-5.12.3_vc14-include.zip contents here)
   │   ├── lib\
   │   └── mkspecs\ (extract included qt-5.12.3_vc14-mkspecs contents here)
   ├── 2022\ (Qt 5.15.2)
   ├── 2023\ (Qt 5.15.2)
   ├── 2024\ (Qt 5.15.2)
   ├── 2025\ (Qt 6.5.3)
   │   ├── cmake\
   │   ├── devkit\
   │   ├── include\
   │   ├── lib\
   │   └── mkspecs\
   │   └── Qt\ (extract this folder from included Qt.zip)
   ├── 2026\ (Qt 6.5.3)
   ├── 2027\ (Qt 6.8.3)
   └── build_maya_cpp_qt_plugin.bat  (for any plugin, including c++ and/or Qt)
   ```

## Building Plugins

### Step 1: Locate Sample Plugins
- Navigate to any version folder: `C:\MayaDevKits\[VERSION]\devkit\plug-ins\`
- You'll find various sample plugins (e.g., `helixQtCmd`, `helloWorld`, etc.)

### Step 2: Compile Plugins Automatically
1. **Drag and drop** any plugin folder onto the `build_maya_cpp_qt_plugin.bat` file
2. The script will automatically:
   - Detect if it's a Qt plugin (looks for `.pro` files)
   - Set up the Visual Studio environment
   - Compile the plugin for all available Maya versions
   - Output `.mll` files to `[plugin_folder]\build\[version]\plug-ins\`
   - Copy any `.mel` files to `[plugin_folder]\build\[version]\scripts\`

### Step 3: Install and Test
1. Copy the generated `.mll` files to Maya's plugin directory:
   ```
   C:\Users\[Username]\Documents\maya\[version]\plug-ins\
   ```
2. Open Maya and load the plugin:
   ```python
   # In Maya's Script Editor
   import maya.cmds as cmds
   cmds.loadPlugin("your_plugin.mll")
   ```

## Project Types Supported

| Type | Description | Build Method | Maya Versions |
|------|-------------|--------------|---------------|
| **C++ Plugins** | Standard Maya API plugins | CMake | All (2020-2027) |
| **Qt Plugins** | Plugins with Qt GUI components | qmake (≤2024), CMake (≥2025) | All (2020-2027) |
| **Python Plugins** | Pure Python scripts | Copy only | All (2020-2027) |
| **PyQt Plugins** | Python with Qt interface | Copy only | All (2020-2027) |

## Advanced Usage

### Manual Build Commands

If you prefer manual building:

**For Qt plugins (Maya 2024 and earlier):**
- Make sure all directories have back-slashes
```cmd
# Open x64 Native Tools Command Prompt for VS 2022
cd path/to/your/plugin
"C:/MayaDevKits/2024/devkit/bin/qmake.exe" your_plugin.pro
nmake release
```

**For all plugins (Maya 2025+):**
- Make sure all directories have back-slashes
```cmd
cmake -H"source_dir" -B"build_dir" -G "Visual Studio 17 2022" -DMAYA_VERSION=2027 -DMAYA_DEVKIT="devkit_dir" -DCMAKE_INSTALL_PREFIX="output_dir"
cmake --build "build_dir" --config Release
```

### Directory Cleanup
To clean build artifacts:
```cmd
# For qmake builds
nmake distclean
rmdir /s /q release debug

# For CMake builds
rmdir /s /q build
```

## Troubleshooting

### Common Issues

**❌ "cl.exe not found" error**
- **Solution**: Run the script from **Developer Command Prompt for Visual Studio**
- Or ensure the batch script includes Visual Studio environment setup

**❌ "Architecture mismatch" warnings**
- **Solution**: Maya requires 64-bit builds. Use `vcvars64.bat`, not `vcvars32.bat`

**❌ Plugin fails to load in Maya**
- **Solution**: Ensure you're using the correct Maya version's DevKit
- Check that all dependencies are properly linked

**❌ Qt-related linking errors**
- **Solution**: For Maya 2024 and earlier, use the DevKit's qmake instead of system Qt

### Getting Help

- **Official Documentation**: [Maya Developer Help Center](https://help.autodesk.com/view/MAYADEV/2027/ENU/)
- **Community Forums**: [Autodesk Maya Programming Forum](https://forums.autodesk.com/t5/maya-programming-forum/bd-p/area-maya-programming)
- **Issue Tracker**: Create issues in this repository for build script problems

## System Requirements

| Component | Requirement |
|-----------|-------------|
| **OS** | Windows 10/11 (64-bit) |
| **Compiler** | Visual Studio 2019/2022 |
| **Architecture** | x64 only |
| **Maya Versions** | 2020, 2022, 2023, 2024, 2025, 2026, 2027 |
| **Disk Space** | ~2GB per Maya version DevKit |

---

## License

This build system is provided as-is. Maya DevKits are licensed under the [Autodesk License Agreement](https://www.autodesk.com/company/legal-notices-trademarks/software-license-agreements). A valid Maya license is required for plugin development and distribution.

**Happy plugin development!**
