# Hướng Dẫn Sửa Secrets trong Commit

## Vấn Đề
GitHub đã chặn push vì phát hiện Stripe secret keys trong commit `91f5e41`.

## Giải Pháp
Đã tạo fixup commit để sửa lỗi. Bây giờ cần chạy rebase để merge fixup commit vào commit gốc.

## Các Bước Thực Hiện

### Bước 1: Chạy Interactive Rebase với Autosquash

```powershell
git rebase -i --autosquash 86119b2707ea0405cb66c04ec0160198905cad79
```

Hoặc đơn giản hơn (rebase 6 commits gần nhất):

```powershell
git rebase -i --autosquash HEAD~6
```

### Bước 2: Trong Editor

Khi editor mở (VS Code, Notepad, v.v.), bạn sẽ thấy danh sách commits. Git đã tự động sắp xếp fixup commit ngay sau commit `91f5e41`.

**Không cần thay đổi gì!** Chỉ cần:
- **Lưu file** (Ctrl+S)
- **Đóng editor**

Git sẽ tự động:
1. Áp dụng fixup commit vào commit `91f5e41`
2. Xóa fixup commit
3. Tiếp tục rebase các commits còn lại

### Bước 3: Kiểm Tra Kết Quả

Sau khi rebase hoàn tất, kiểm tra:

```powershell
git log --oneline -6
```

Commit `91f5e41` giờ đã được cập nhật và không còn chứa secrets.

### Bước 4: Push Lên GitHub

```powershell
git push origin main
```

Bây giờ push sẽ thành công vì secrets đã được xóa khỏi lịch sử commit.

## Nếu Gặp Lỗi

### Nếu rebase bị conflict:

```powershell
# Giải quyết conflicts trong các file
# Sau đó:
git add .
git rebase --continue
```

### Nếu muốn hủy rebase:

```powershell
git rebase --abort
```

### Nếu editor không mở:

Có thể cần set editor:

```powershell
# Dùng VS Code
$env:GIT_EDITOR = "code --wait"
git rebase -i --autosquash HEAD~6

# Hoặc dùng Notepad
$env:GIT_EDITOR = "notepad"
git rebase -i --autosquash HEAD~6
```

## Tóm Tắt

1. ✅ Đã xóa secrets khỏi files
2. ✅ Đã tạo fixup commit
3. ⏳ **Cần chạy**: `git rebase -i --autosquash HEAD~6`
4. ⏳ **Lưu và đóng editor**
5. ⏳ **Push**: `git push origin main`

