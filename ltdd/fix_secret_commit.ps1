# Fix secret in current commit
if (Test-Path "STRIPE_PAYMENT_SETUP.md") {
    $content = Get-Content "STRIPE_PAYMENT_SETUP.md" -Raw
    $content = $content -replace 'sk_test_51SkM1bF20g1EMWhN9IkmSiRMEHQJbM0HUr6nYa6vz7IXfbWHfmmROrw1mbzjivS3989mn3zNUKdan8Q6sbFGfRob00TkydFF7A', 'sk_test_YOUR_STRIPE_SECRET_KEY_HERE'
    Set-Content "STRIPE_PAYMENT_SETUP.md" -Value $content -NoNewline
    git add STRIPE_PAYMENT_SETUP.md
}
if (Test-Path "GOOGLE_PAY_CONFIGURATION_COMPLETE.md") {
    $content = Get-Content "GOOGLE_PAY_CONFIGURATION_COMPLETE.md" -Raw
    $content = $content -replace 'sk_test_51SkM1bF20g1EMWhN9IkmSiRMEHQJbM0HUr6nYa6vz7IXfbWHfmmROrw1mbzjivS3989mn3zNUKdan8Q6sbFGfRob00TkydFF7A', 'sk_test_YOUR_STRIPE_SECRET_KEY_HERE'
    Set-Content "GOOGLE_PAY_CONFIGURATION_COMPLETE.md" -Value $content -NoNewline
    git add GOOGLE_PAY_CONFIGURATION_COMPLETE.md
}

