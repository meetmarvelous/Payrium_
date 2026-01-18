import os
import re

# Configuration
target_dir = r"c:\Users\dell\Desktop\Payrium_"
style_block = """
  <style>
    /* Custom scrollbar hiding for horizontal scroll areas */
    .no-scrollbar::-webkit-scrollbar {
      display: none;
    }

    .no-scrollbar {
      -ms-overflow-style: none;
      scrollbar-width: none;
    }

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
</head>"""

# Regex patterns
head_pattern = re.compile(r'</head>', re.IGNORECASE)
body_pattern = re.compile(r'<body([^>]*)>', re.IGNORECASE)
# Matches navs that are md:hidden (mobile navs) and have some positioning (absolute/fixed/etc)
nav_pattern = re.compile(r'<nav\s+class="(?=.*md:hidden)(?=.*bottom-0)[^"]*"', re.IGNORECASE)

# Correct nav class
fixed_nav_class = 'class="md:hidden fixed bottom-0 left-0 right-0 bg-white dark:bg-surface-dark border-t border-slate-100 dark:border-slate-800 px-6 py-3 pb-safe flex justify-between items-center z-50"'

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    modified = False

    # 1. Inject Style Block (avoid duplicates)
    if '.h-screen-safe' not in content:
        if '<style>' in content and '.no-scrollbar' in content:
            # Replace existing style block if it looks like the standard one
            # This is a bit risky with regex, better to just append if specific dvh class is missing
            pass # simpler to just replace </head> and let it be
        
        # We will try to find the standard style block end or just insert before </head>
        # Actually, let's just insert before </head> if the specific class isn't there.
        # But we don't want to duplicate .no-scrollbar if it exists.
        
        if '.no-scrollbar' in content:
             # Just add the new css parts to existing style or replace.
             # Easier: check if we can cleanly replace the whole closing head tag with our block
             # But we might duplicate .no-scrollbar.
             # Let's construct a smart block.
             new_styles = """
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
</head>"""
             if '</style>' in content:
                 content = content.replace('</style>\n</head>', new_styles.replace('</head>', '').strip() + '\n</style>\n</head>')
                 content = content.replace('</style>\r\n</head>', new_styles.replace('</head>', '').strip() + '\n</style>\n</head>')
                 # If simple replace didn't work (whitespace issues), fallback to append
                 if 'h-screen-safe' not in content:
                     content = content.replace('</head>', new_styles)
             else:
                 content = content.replace('</head>', style_block)
             modified = True
        else:
             content = content.replace('</head>', style_block)
             modified = True

    # 2. Update Body Class
    # We want to ensure h-screen-safe is present if h-screen or min-h-screen is there
    def update_body_class(match):
        attrs = match.group(1)
        if 'h-screen-safe' in attrs:
            return match.group(0) # Already has it
        
        # replace existing height classes to avoid conflicts? 
        # Actually, adding h-screen-safe alongside min-h-screen is fine due to !important in CSS
        # But we should prefer h-screen as base.
        
        # Simplest approach: Append the class
        if 'class="' in attrs:
            new_attrs = attrs.replace('class="', 'class="h-screen-safe ')
            return f'<body{new_attrs}>'
        return match.group(0)

    # Only apply if we haven't manually fixed it (check for the class)
    if 'h-screen-safe' not in content:
        content = body_pattern.sub(update_body_class, content)
        modified = True

    # 3. Fix Bottom Nav
    # We want to standardize the nav class.
    # We look for navs that are likely the bottom nav bar.
    if '<nav' in content and 'md:hidden' in content:
        # Check if we should update the class
        def update_nav(match):
            return f'<nav {fixed_nav_class}'
        
        # We only want to touch the bottom nav.
        new_content = nav_pattern.sub(update_nav, content)
        if new_content != content:
            content = new_content
            modified = True

    if modified and content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

# Main loop
count = 0
for root, dirs, files in os.walk(target_dir):
    for file in files:
        if file.endswith(".html"):
            path = os.path.join(root, file)
            # Skip file if it appears to be already fixed manually (has h-screen-safe AND fixed nav)
            # But the script handles checks internally.
            try:
                if process_file(path):
                    print(f"Fixed: {file}")
                    count += 1
            except Exception as e:
                print(f"Error processing {file}: {e}")

print(f"Total files updated: {count}")
