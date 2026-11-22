# ClaudeMini 0.8.0 — Đăng nhập Google hoặc API key, và sửa lỗi treo

## Mới ở 0.8.0
- **Đăng nhập bằng tài khoản Google** cho Gemini, bên cạnh API key. Trên màn hình nhập key có nút **Đăng nhập bằng Google** (chỉ hiện khi bản build có client ID, xem bên dưới). Đăng nhập xong, app kiểm tra Gemini có chấp nhận quyền đó không; nếu không, app tự đăng xuất Google và báo lỗi (HTTP) để bạn biết.
- Khi lưu một API key mới, app chuyển sang dùng key đó. Khi đăng nhập Google, app dùng tài khoản Google. Nút đăng xuất ở màn hình này sẽ xóa đúng cái đang dùng.
- Token của Google được làm mới tự động khi app mở lại, và ngay trước mỗi yêu cầu.
- **Sửa lỗi treo không trả lời:** khi model suy nghĩ quá lâu (không gửi dữ liệu trong 180 giây), trước đây app tự thử lại âm thầm tối đa 14 lần, mỗi lần chờ thêm 180 giây, nên trông như treo gần 40 phút. Bây giờ app báo lỗi ngay sau lần chờ đầu tiên, với gợi ý hạ mức suy luận trong Cài đặt. Các lỗi mạng khác vẫn được thử lại nhưng tối đa 3 lần.

### Cách bật đăng nhập Google (làm một lần)
1. Trong Google Cloud Console, tạo một project, bật **Generative Language API** (Gemini API), và cấu hình **OAuth consent screen** (User type: External, thêm email của bạn vào Test users).
2. Tạo **OAuth client ID** loại **iOS**, với Bundle ID `com.puc.claudemini`. Copy client ID dạng `123456-abc.apps.googleusercontent.com`.
3. Trong repo GitHub của bạn: Settings › Secrets and variables › Actions › tab **Variables**, tạo `GOOGLE_OAUTH_CLIENT_ID` với giá trị trên. Chạy lại workflow build.
4. Nếu không đặt biến này, bản build vẫn chạy bình thường bằng API key; chỉ không có nút Google.

### Lưu ý quan trọng
- Yêu cầu đăng nhập Google đi qua **project Google Cloud của client ID** chứ không phải hạn mức cá nhân của tài khoản đăng nhập. Nghĩa là hạn mức tính vào project bạn tạo ra.
- Phạm vi (scope) của Gemini khi đăng nhập bằng OAuth được khai báo trong `src/GoogleAuth.m` (`kScopes`). Nếu đăng nhập được nhưng Gemini báo 403, đó là chỗ cần kiểm tra trước.
- Bản 0.8.0 được viết mà chưa biên dịch và chưa chạy trên máy thật. Hãy build và thử đăng nhập một lần, rồi xem **Cài đặt › Nhật ký chẩn đoán** nếu có lỗi.

---

## Phiên bản trước


🧠 AI — Suy luận & Tạo nội dung

• Ép mức suy luận mặc định lên Cao (High): AI phân tích sâu hơn, trả lời chi tiết và mạch lạc hơn.

• Luôn cho phép tạo ảnh & tệp: chỉ dẫn hệ thống được bổ sung ngầm — AI luôn được phép tạo ảnh (dùng định dạng Markdown) và tạo tệp/mã nguồn (khối code), không bao giờ trả lời "Tôi không thể tạo ảnh/tệp".

🎙️ Trò chuyện bằng giọng nói (mới)

• Ghi âm & Nhận dạng giọng nói tiếng Việt: nhấn nút 🎤 để nói, nội dung tự chuyển thành chữ vào ô nhập — xem trước rồi gửi.

• Đọc câu trả lời ra âm thanh: AI trả lời xong tự động đọc bằng giọng nói rõ ràng; bật/tắt trong Cài đặt.

• Yêu cầu quyền Microphone khi dùng lần đầu — chỉ hoạt động khi bạn chủ động nhấn nút ghi âm.

🔧 Sửa lỗi

• Sửa: giá trị "Độ dài lịch sử gửi cho AI" hiển thị không khớp với danh sách lựa chọn — đồng bộ hóa đúng từ 1 triệu đến 100 triệu ký tự.

• Sửa: một số định dạng tệp nén bị báo lỗi không hỗ trợ dù là hợp lệ.

• Cải thiện: luồng suy luận không còn bị ngắt quãng khi tạo ảnh hoặc xử lý tệp lớn.
📋 Tính năng chính (từ bản trước)

• Chat Gemini & Claude: nhập API key của bạn, lưu an toàn trên máy

• Sửa tin nhắn cũ: chỉnh sửa bất kỳ tin nào và gửi lại từ vị trí đó

• Tạo ảnh, phân tích ảnh/PDF/video, xuất Word/TXT

• Giới hạn linh hoạt: độ dài lịch sử, giới hạn token đầu ra, mức suy luận từ Thấp đến Tối đa

• 7 giao diện sẵn có: Claude, SideStore, LiveContainer, Dopamine, Chimera, Sileo, GitHub

• Chế độ Sáng/Tối/Tự động, đổi icon ứng dụng, nền chat tùy chỉnh

• Lưu lịch sử trên máy, tìm kiếm, xuất/xóa dễ dàng
⚙️ Thông tin kỹ thuật

• Phiên bản: 0.7.1 | iOS yêu cầu: 12.0+

• Kiến trúc: arm64 | Định dạng: .deb (rootful) / .ipa (sandbox)

• Frameworks bổ sung: Speech.framework, AVFoundation.framework (cho tính năng giọng nói)

• Build tương tự hướng dẫn cũ — thay thế file và build bình thường
💡 Mọi thay đổi đều giữ nguyên tương thích với dữ liệu và cài đặt của bản 0.7.0 — chỉ cần cài đè là dùng ngay, không cần xóa dữ liệu.

## Mới ở 0.6.0: file .ipa
Mỗi lần build, GitHub Actions tạo thêm một artifact thứ hai tên **ClaudeMini-ipa** chứa file IPA theo số phiên bản hiện tại (artifact `ClaudeMini-deb` vẫn có như cũ).
- **Dành cho máy đã jailbreak có AppSync Unified** (cài từ Sileo). File được ký giả bằng `ldid`, không có chữ ký của Apple, nên máy chưa jailbreak không cài được. Cài bằng Filza (chạm vào file `.ipa` rồi chọn Install) hoặc một công cụ cài IPA khác trên máy jailbreak. Để cài trên máy không jailbreak cần ký lại bằng chữ ký của chính bạn (ví dụ Sideloadly hoặc AltStore); mình chưa kiểm tra chúng có hỗ trợ iOS 12 hay không.
- **Khác với `.deb`:** bản `.ipa` chạy trong sandbox bình thường như app App Store (không dùng quyền đặc biệt `platform-application` và `no-container` của bản `.deb`). Lịch sử và API key nằm trong thư mục riêng của app. Bản `.deb` thì cài như ứng dụng hệ thống vào `/Applications`.
- **Đừng cài cả hai cùng lúc:** hai bản trùng bundle id `com.puc.claudemini`. Hãy gỡ bản này trước khi cài bản kia. Dữ liệu của hai bản không dùng chung.
- File tạo bằng `tools/make_ipa.sh`, quyền dùng nằm trong `app/entitlements-ipa.plist`.

## Mới ở 0.5.2
- **Câu chào theo giờ** ở màn hình chat trống, lấy giờ của thiết bị: **03:00–10:59** Chào buổi sáng, **11:00–13:59** Chào buổi trưa, **14:00–17:59** Chào buổi chiều, **18:00–22:59** Chào buổi tối, **23:00–02:59** Chào cú đêm. Có cả tiếng Anh. Mốc giờ nằm ở hàm `greetingTitle` trong `src/ChatViewController.m`.
- **Sáu câu hỏi thay đổi** dưới lời chào (câu cũ "Hôm nay bạn muốn học gì?" và 5 câu mới), chọn ngẫu nhiên mỗi lần mở app hoặc bấm cuộc trò chuyện mới, không lặp lại câu liền trước. Chữ nằm trong `Localizable.strings` (`greeting_*`, `empty_sub_1` đến `empty_sub_6`).
- Nếu bạn để app mở qua một mốc giờ khi chat còn trống, lời chào tự đổi khi quay lại app.

## Mới ở 0.5.1
- **Icon mới** (ngôi sao nhiều màu trên nền sáng). Ảnh được xóa watermark, đưa về hình vuông, xuất đủ kích thước cho iPhone, và dùng luôn cho logo trong app và ảnh khởi động.
- **Bạn không cần repo Sileo.** Bước `publish` tự bỏ qua khi bạn chưa cài `SILEO_TOKEN` và `SILEO_REPO`. Chỉ cần chạy **Build ClaudeMini** trong tab Actions rồi tải file `.deb` trong mục Artifacts (tên `ClaudeMini-deb`), sau đó chép vào máy và cài bằng Filza hoặc `dpkg -i`.

## Mới ở 0.5.0 (giai đoạn 4)

**4A. Nhật ký chẩn đoán.** Cài đặt › Nhật ký chẩn đoán. App ghi lại các sự kiện và mã lỗi (mở app, kiểm tra key, mỗi yêu cầu gửi đi và kết quả, nhập tệp, lỗi của trang chat, WebKit bị iOS tắt…) để bạn báo lỗi bằng sự thật thay vì đoán. Có nút **Sao chép** và **Xóa**. App không ghi API key, nội dung tin nhắn hay tên tệp; lời báo lỗi do Google/Anthropic trả về được giữ nguyên, nên hãy đọc qua trước khi gửi cho ai.

**4B. Tự đưa bản build vào repo Sileo.** Workflow có thêm bước `publish`, chỉ chạy khi bạn đã cài đặt (nếu chưa, nó bỏ qua và bản `.deb` vẫn có trong Artifacts):
1. Trên GitHub: Settings › Developer settings › Personal access tokens › **Fine-grained tokens** › Generate. Chọn **Only select repositories** và chỉ chọn repo Sileo của bạn. Mục Permissions đặt **Contents: Read and write**. Sao chép token.
2. Trong repo ClaudeMini: Settings › Secrets and variables › Actions. Tab **Secrets**: tạo `SILEO_TOKEN` (dán token). Tab **Variables**: tạo `SILEO_REPO` (ví dụ `tenban/repo-sileo`).
3. Tùy chọn (tab Variables): `SILEO_BRANCH` (nhánh, mặc định là nhánh chính của repo) và `SILEO_DEBS_DIR` (thư mục chứa file .deb, mặc định `debs`).
Sau mỗi lần build, `tools/publish_repo.py` chép `.deb` vào thư mục đó, thay **đúng một mục** của ClaudeMini trong `Packages` (các gói khác giữ nguyên từng byte), tạo lại `Packages.gz/.bz2/.xz`, cập nhật hash trong `Release` rồi commit. Giữ 3 phiên bản mới nhất của ClaudeMini, xóa bản cũ hơn.
- **Nếu repo của bạn có chữ ký** (có `InRelease` hoặc `Release.gpg`), công cụ **từ chối** chạy để không làm hỏng chữ ký.
- **Giả định bố cục:** tệp `Packages` và `Release` nằm ở thư mục gốc của repo. Nếu repo của bạn để ở chỗ khác, hãy cho mình biết.
- Lần đầu nên sao lưu repo (tải bản zip) để yên tâm.

**4C. Bớt gửi lại ảnh, PDF và khung hình video.** Cài đặt › Ảnh, PDF và video đã gửi: **1 tin gần nhất / 3 tin gần nhất (mặc định) / Tất cả**. AI chỉ nhìn thấy ảnh, khung hình video và PDF khi chúng được gửi lại trong từng yêu cầu, nên gửi ít hơn thì tiết kiệm hạn mức, nhưng AI không còn xem được nội dung media cũ hơn (nó thấy một ghi chú thay thế). Chữ trích từ Word, PowerPoint, văn bản luôn được giữ. Mình chưa làm cách tải tệp lên một lần (Files API) vì chưa chắc nó tiết kiệm được hạn mức và cần thử với key thật.

**4D. Chỉ dẫn riêng cho từng cuộc trò chuyện.** Chạm vào tên model ở giữa thanh trên cùng (màn hình giờ tên là **Model và chỉ dẫn**): dòng đầu tiên là chỉ dẫn riêng cho cuộc trò chuyện đang mở, thay cho chỉ dẫn chung trong Cài đặt. Để trống là dùng chỉ dẫn chung. Lưu cùng cuộc trò chuyện.

## Mới ở 0.4.0 (giai đoạn 3)

**Câu trả lời hiển thị đẹp.** Dấu `**` giờ thành chữ in đậm, và còn có: tiêu đề, danh sách, bảng (cuộn ngang được), trích dẫn, liên kết, khối code tô màu có nút **Sao chép** (Python, JavaScript, C/C++, Java, SQL, HTML, Bash, Pascal, LaTeX, MATLAB…) và **công thức toán** (`$...$`, `$$...$$`, `\(...\)`, `\[...\]`). Mã HTML trong câu trả lời không bao giờ được chạy, chỉ hiện thành chữ. Công thức chưa viết xong lúc chữ đang chạy hiện tạm dạng chữ, đóng xong mới hiện thành công thức. Chữ tiếng Việt có dấu nằm trong công thức dùng font dự phòng nên khoảng cách có thể lệch nhẹ.

**Thêm Claude (Anthropic).** Cài đặt có hai mục: **API key Gemini** và **API key Claude**; có thể dùng một hoặc cả hai. Lần đầu mở app có công tắc Gemini | Claude để chọn key nhập trước. Danh sách model lấy trực tiếp từ từng nhà cung cấp, và model nào thì app tự dùng đúng nhà cung cấp đó; bạn có thể đổi model giữa chừng, lịch sử được gửi lại theo đúng định dạng của nhà cung cấp mới.
- **Key Claude không có gói miễn phí.** Cần nạp credit trước tại console.anthropic.com (mục Plans & Billing). Gói Claude Pro/Max là sản phẩm riêng và không cấp quyền dùng API. Hết credit, app báo rõ.
- Mặc định: có key Gemini thì dùng Gemini Flash mới nhất; chỉ có key Claude thì dùng Claude Sonnet mới nhất. Model Haiku rẻ hơn Sonnet.
- Ảnh và PDF gửi được cho cả hai nhà cung cấp.

**Chỉ dẫn cho AI (system prompt).** Cài đặt › Chỉ dẫn cho AI: một ô tự nhập (tối đa 100.000 ký tự), được gửi kèm mọi tin nhắn, lưu tự động. Áp dụng cho toàn app.

**Đổi ngôn ngữ.** Cài đặt › Ngôn ngữ: Tự động / Tiếng Việt / English. Đổi xong app dựng lại màn hình bằng ngôn ngữ mới (cuộc trò chuyện đang mở bắt đầu lại từ đầu).

**Chạm vào ảnh trong cuộc trò chuyện** để xem toàn màn hình, véo hai ngón hoặc chạm đúp để phóng to, chạm một lần để đóng.

## Mới ở 0.3.0: gửi ảnh và tài liệu
Nút **+** bên trái ô nhập mở menu: **Chụp ảnh**, **Chọn ảnh từ thư viện**, **Chọn tệp**. Tệp chờ gửi hiện thành ảnh nhỏ/thẻ phía trên ô nhập (bấm × để bỏ). Bạn có thể gửi tệp kèm câu hỏi, hoặc chỉ gửi tệp.

| Loại | Cách xử lý |
|---|---|
| Ảnh (JPG, PNG, HEIC, GIF…) | Thu nhỏ còn tối đa 2048 px, nén JPEG rồi gửi cho Gemini hoặc Claude |
| PDF (tối đa 10 MB) | Gửi nguyên cho Gemini hoặc Claude, đọc được cả bản scan và hình trong PDF |
| Video MOV/MP4 (tối đa 100 MB, 120 giây) | Trích tối đa 6 khung hình đại diện, gửi như ảnh; không gửi âm thanh |
| Word `.docx`, PowerPoint `.pptx` (tối đa 15 MB) | App tự trích chữ trên máy rồi gửi dạng văn bản (không đọc được ảnh/biểu đồ bên trong) |
| Văn bản, mã nguồn (`.txt`, `.md`, `.csv`, `.json`, `.py`…) | Gửi dạng văn bản (tối đa 4 MB, cắt còn 200.000 ký tự) |
| `.doc`, `.xls/.xlsx`, `.ppt`, `.pages`, `.rtf`… | Chưa hỗ trợ: hãy xuất sang PDF rồi gửi |

Giới hạn: tối đa 6 tệp mỗi tin nhắn; tổng dữ liệu ảnh, PDF và khung hình video trong một tin nhắn tối đa 13 MB.
Lưu ý quan trọng: API không tự giữ các tệp media cũ giữa các lượt, nên ảnh, khung hình video và PDF đã gửi được **gửi lại ở mỗi lượt** trong cùng cuộc trò chuyện (trong giới hạn dung lượng; tệp cũ nhất sẽ bị bỏ trước). Với tài liệu dài, nên bắt đầu cuộc trò chuyện mới khi chuyển sang chủ đề khác để tiết kiệm hạn mức.
Tệp đính kèm lưu trên máy (cùng lịch sử) và bị xóa khi bạn xóa cuộc trò chuyện hoặc toàn bộ lịch sử. Lần đầu dùng camera, iOS sẽ hỏi quyền.

## Thay đổi ở 0.2.2
- **Màn chọn model chia hai nhóm.** "Khuyên dùng cho key miễn phí" (họ Flash và Flash-Lite, mới nhất lên đầu) và "Có thể cần trả phí hoặc bị giới hạn" (Pro, Argon và các loại khác). Đây chỉ là gợi ý theo tên họ model, vì Google không cho biết điều này qua API.
- **Model mặc định luôn ưu tiên họ Flash,** không bao giờ tự chọn model trả phí khi đã có Flash/Flash-Lite trong danh sách.
- Thông báo "vượt hạn mức" giờ gợi ý chọn model khác.

## Nên dùng model nào với key miễn phí
Theo các nguồn tháng 10/2026 (Google không còn công bố hạn mức từng model, xem số liệu thật trong trang rate-limit của Google AI Studio):
- Chính: `gemini-3.8-flash` (mặc định). Dự phòng: `gemini-3.6-flash`.
- Nhẹ và nhanh: `gemini-3.5-flash-lite`, `gemini-3.1-flash-lite`, hoặc dòng 2.5 (`gemini-2.5-flash`, `gemini-2.5-flash-lite`).
- Cần trả phí: Gemini 4 Argon và các bản Pro. Riêng `gemini-2.5-pro` các nguồn chưa thống nhất.
- Gói miễn phí: Google có thể dùng nội dung bạn gửi để cải thiện sản phẩm của họ.

## Chưa có
- Tải tệp lên một lần rồi tham chiếu (Files API) để khỏi gửi lại PDF/ảnh.
- Ký repo Sileo (bước tự lên repo từ chối repo có chữ ký).

## Cách build (không cần Mac)
1. Tải **toàn bộ thư mục này** lên repo GitHub (giữ thư mục ẩn `.github`).
2. Tab **Actions** → **Build ClaudeMini** → **Run workflow**.
3. Tải artifact `ClaudeMini-deb` (hoặc `ClaudeMini-ipa` nếu bạn muốn file .ipa), lấy file `com.puc.claudemini_0.7.0_iphoneos-arm.deb`.
4. Đưa vào repo Sileo của bạn (hoặc chép vào máy và cài bằng Filza). Số phiên bản lớn hơn bản trước nên Sileo sẽ coi là bản cập nhật.

## Những gì cần để ý khi chạy thử lần đầu
- **Khung chat dùng WebKit.** Nếu sau khoảng 12 giây khung chat không hiện, app sẽ báo "Không mở được khung chat" kèm chi tiết. Hãy chụp lại thông báo đó gửi cho người hỗ trợ.
- Nếu một model có trong danh sách nhưng bị báo "không dùng được với key của bạn", hãy chọn model khác (Google có thể giới hạn quyền dùng một số model).
- Key miễn phí của Google có hạn mức theo phút/ngày. Khi vượt, app báo rõ và bạn thử lại sau.

## Cấu trúc
- `app/Resources/web/` — trang chat. `vendor.js` và `vendor.css` là markdown-it, highlight.js và KaTeX (đã chuyển xuống ES2018 cho Safari 12, font toán nhúng sẵn), tạo bằng `tools/build_web.py` (chỉ chạy khi muốn cập nhật thư viện, không cần cho việc build app); `render.js` là bộ hiển thị markdown/toán; `chat.js` là trang chat
- `tools/publish_repo.py` — cập nhật repo Sileo (đã thử trên repo giả lập); `src/DiagnosticLog.m` — nhật ký chẩn đoán
- `src/ClaudeStream.m`, `src/ClaudeClient.m` — gọi API Claude; `src/GeminiStream.m` — gọi API Gemini; `src/KeyStore.m` — lưu key từng nhà cung cấp
- `src/OfficeText.c` — bộ trích chữ Word/PowerPoint viết bằng C thuần (đã thử trên tệp thật và dữ liệu hỏng); `src/AttachmentStore.m` — lưu và xử lý tệp đính kèm
- `src/` — mã Objective-C: `ChatViewController` (màn chính), `GeminiStream` (gọi API dạng stream), `GeminiClient` (kiểm tra key, lấy danh sách model), `ConversationStore` (lịch sử), `ModelStore`, `HistoryViewController`, `SettingsViewController`, `ModelPickerViewController`, `RootViewController` (màn nhập key)
- `app/Resources/web/` — trang chat (HTML/CSS/JS viết kiểu cũ ES5 cho Safari 12)
- `app/` — `Info.plist`, quyền, icon, ảnh khởi động, chuỗi dịch
- `deb/DEBIAN/` — thông tin gói, script `postinst`/`postrm` (chạy `uicache`)
- `tools/make_ipa.sh` — đóng gói file .ipa; `app/entitlements-ipa.plist` — quyền của bản .ipa
- `build.sh`, `.github/workflows/build.yml` — build và đóng gói
- `VERSION` — số phiên bản; tăng số này mỗi lần cập nhật

## Lưu ý
- Trường `Maintainer` trong `deb/DEBIAN/control` đang là giá trị tạm (`puc`). Hãy sửa theo ý bạn.
- Lịch sử chỉ lưu trên máy này. Khi chat, nội dung được gửi tới nhà cung cấp model đang chọn (Google Gemini hoặc Anthropic Claude) bằng API key của bạn.
