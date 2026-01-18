$targetDir = "c:\Users\dell\Desktop\Payrium_"
$htmlFiles = Get-ChildItem -Path $targetDir -Recurse -Filter "*.html"

$safeCss = @"
  <style>
    /* Dynamic viewport height for mobile browsers */
    @supports (height: 100dvh) {
      .h-screen-safe {
        height: 100dvh !important;
      }
    }

    /* Safe area insets for notched devices */
    .pb-safe {
      padding-bottom: env(safe-area-inset-bottom, 0px);
    }
  </style>
</head>
"@

$standardNavClass = 'class="md:hidden fixed bottom-0 left-0 right-0 bg-white dark:bg-surface-dark border-t border-slate-100 dark:border-slate-800 px-6 py-3 pb-safe flex justify-between items-center z-50"'

foreach ($file in $htmlFiles) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $modified = $false

    # 1. Inject CSS if missing
    if ($content -notmatch "h-screen-safe") {
        if ($content -match "</head>") {
            $content = $content -replace "</head>", $safeCss
            $modified = $true
        }
    }

    # 2. Update Body Class
    # We look for body tag. If it doesn't have h-screen-safe, we append it to class list.
    if ($content -match "<body") {
        if ($content -notmatch 'body[^>]*class="[^"]*h-screen-safe') {
             $content = $content -replace '<body([^>]*)class="([^"]*)"', '<body$1class="$2 h-screen-safe"'
             $modified = $true
        }
    }

    # 3. Fix Bottom Nav
    # We search for the mobile nav by characteristic classes
    if ($content -match '<nav[^>]*class="[^"]*md:hidden[^"]*bottom-0[^"]*"') {
        # Replace the class attribute
        $content = [regex]::Replace($content, 
            '<nav([^>]*)class="[^"]*md:hidden[^"]*bottom-0[^"]*"', 
            "<nav`$1$standardNavClass")
        $modified = $true
    }

    if ($modified) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8
        Write-Host "Fixed: $($file.Name)"
    }
}
