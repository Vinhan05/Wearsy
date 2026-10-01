package app.wearsy.mobile

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Chặn chụp màn hình và hiển thị trong danh sách ứng dụng gần đây
        // Bảo vệ thông tin nhạy cảm trên màn hình đăng nhập
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
