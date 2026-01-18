$targetDir = "c:\Users\dell\Desktop\Payrium_"
$htmlFiles = Get-ChildItem -Path $targetDir -Recurse -Filter "*.html"

# Nav Template Blocks
$navStart = '<nav class="md:hidden fixed bottom-0 left-0 right-0 bg-white dark:bg-surface-dark border-t border-slate-100 dark:border-slate-800 px-6 py-3 pb-safe flex justify-between items-center z-50">'
$navEnd = '</nav>'

# Item Templates
# 0: href, 1: text-color-class, 2: group-class, 3: scale-class, 4: active-bar, 5: fill-settings, 6: font-weight
# Note: I will build simplified strings instead of complex format strings.

function Get-NavItem {
    param(
        [string]$Href,
        [string]$Label,
        [string]$Icon,
        [bool]$IsActive
    )

    if ($IsActive) {
        # Active Style (DAO Style)
        return @"
    <a href="$Href" class="flex flex-col items-center gap-1 text-primary w-14 relative">
        <div class="absolute -top-3 left-1/2 -translate-x-1/2 w-8 h-1 bg-primary rounded-b-full"></div>
        <span class="material-symbols-outlined" style="font-variation-settings: 'FILL' 1;">$Icon</span>
        <span class="text-[10px] font-bold">$Label</span>
    </a>
"@
    } else {
        # Inactive Style
        return @"
    <a href="$Href" class="flex flex-col items-center gap-1 text-slate-400 hover:text-primary transition-colors group w-14">
        <span class="material-symbols-outlined group-hover:scale-110 transition-transform">$Icon</span>
        <span class="text-[10px] font-medium">$Label</span>
    </a>
"@
    }
}

foreach ($file in $htmlFiles) {
    if ($file.Name -eq "fix_responsive.ps1") { continue }

    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    
    # Only process files that HAVE a bottom nav to replace
    if ($content -match '<nav[^>]*class="[^"]*md:hidden[^"]*bottom-0[^"]*"') {
        
        # Determine relative path prefix
        # Assume project structure is Root/Category/File.html
        # If file is in Root, prefix is "Category/"
        # If file is in Category, prefix is "../Category/" (unless same category)
        
        $parentDirName = $file.Directory.Name
        $isRoot = ($file.Directory.FullName -eq $targetDir)

        function Get-RelPath {
            param([string]$targetCat, [string]$targetFile)
            if ($isRoot) {
                return "$targetCat/$targetFile"
            } elseif ($parentDirName -eq $targetCat) {
                return "$targetFile"
            } else {
                return "../$targetCat/$targetFile"
            }
        }

        $dashLink = Get-RelPath "Dashboard" "Dashboard MO.html"
        $actLink = Get-RelPath "Dashboard" "activity.html"
        $daoLink = Get-RelPath "DAO" "dao_governance.html"
        $setLink = Get-RelPath "Settings" "settings_home.html"

        # Determine Active State
        $activeItem = "Dashboard" # Default
        
        if ($file.Name -match "activity") {
            $activeItem = "Activity"
        } elseif ($parentDirName -eq "Settings") {
            $activeItem = "Settings"
        } elseif ($parentDirName -eq "DAO") {
            $activeItem = "DAO"
        } elseif ($parentDirName -eq "Dashboard") {
            if ($file.Name -eq "Dashboard MO.html") { $activeItem = "Dashboard" }
            # implicit else: defaults to dashboard for other dash files?
        }
        
        # Build the new Nav Inner HTML
        $navInner = ""
        $navInner += Get-NavItem -Href $dashLink -Label "Dashboard" -Icon "dashboard" -IsActive ($activeItem -eq "Dashboard")
        $navInner += "`n"
        $navInner += Get-NavItem -Href $actLink -Label "Activity" -Icon "receipt_long" -IsActive ($activeItem -eq "Activity")
        $navInner += "`n"
        $navInner += Get-NavItem -Href $daoLink -Label "DAO" -Icon "how_to_vote" -IsActive ($activeItem -eq "DAO")
        $navInner += "`n"
        $navInner += Get-NavItem -Href $setLink -Label "Settings" -Icon "settings" -IsActive ($activeItem -eq "Settings")

        # Regex Replace the nav block
        # We look for <nav ... md:hidden ... bottom-0 ... > ... </nav>
        
        $navRegex = [regex] '(?s)<nav[^>]*class="[^"]*md:hidden[^"]*bottom-0[^"]*"[^>]*>.*?</nav>'
        
        $newNavBlock = "$navStart`n$navInner`n$navEnd"
        
        $newContent = $navRegex.Replace($content, $newNavBlock)
        
        if ($newContent -ne $content) {
            Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
            Write-Host "Updated Nav: $($file.Name) (Active: $activeItem)"
        }
    }
}
