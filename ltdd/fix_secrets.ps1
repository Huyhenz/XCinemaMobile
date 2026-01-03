# Script to remove secrets from git history
$secretKey = "sk_test_51SkM1bF20g1EMWhN9IkmSiRMEHQJbM0HUr6nYa6vz7IXfbWHfmmROrw1mbzjivS3989mn3zNUKdan8Q6sbFGfRob00TkydFF7A"
$replacement = "sk_test_YOUR_STRIPE_SECRET_KEY_HERE"

# Get all commits that need to be fixed
$commits = git log --oneline origin/main..HEAD | ForEach-Object { $_.Split(' ')[0] }

foreach ($commit in $commits) {
    Write-Host "Processing commit $commit"
    
    # Checkout the commit
    git checkout $commit --quiet
    
    # Fix STRIPE_PAYMENT_SETUP.md if it exists
    if (Test-Path "STRIPE_PAYMENT_SETUP.md") {
        $content = Get-Content "STRIPE_PAYMENT_SETUP.md" -Raw
        $content = $content -replace [regex]::Escape($secretKey), $replacement
        Set-Content "STRIPE_PAYMENT_SETUP.md" -Value $content -NoNewline
    }
    
    # Fix GOOGLE_PAY_CONFIGURATION_COMPLETE.md if it exists
    if (Test-Path "GOOGLE_PAY_CONFIGURATION_COMPLETE.md") {
        $content = Get-Content "GOOGLE_PAY_CONFIGURATION_COMPLETE.md" -Raw
        $content = $content -replace [regex]::Escape($secretKey), $replacement
        Set-Content "GOOGLE_PAY_CONFIGURATION_COMPLETE.md" -Value $content -NoNewline
    }
}

