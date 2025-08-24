require "import"
import "android.app.*"
import "android.os.*"
import "android.view.*"
import "android.widget.*"
import "android.webkit.*"
import "android.net.Uri"
import "android.content.Intent"
import "android.app.AlertDialog"
import "android.widget.Toast"

activity.setTheme(R.Theme_Blue)
activity.setTitle("浏览器")
activity.ActionBar.hide()

-- 布局：放一个 WebView
local layout={
  LinearLayout,
  layout_width="fill",
  layout_height="fill",
  {
    LuaWebView,
    id="wv",
    layout_width="fill",
    layout_height="fill",
  },
}
activity.setContentView(loadlayout(layout))

-- 添加JS接口
local bridge = {}
function bridge.setUserAgent(ua)
  local s = wv.getSettings()
  s.setUserAgentString(tostring(ua))
end
wv.addJavascriptInterface(bridge, "lua")

-- 添加 doExit 函数
function doExit()
  activity.finish() -- 关闭当前 Activity
end

-- WebView 设置
local s = wv.getSettings()
s.setJavaScriptEnabled(true)
s.setDomStorageEnabled(true)
s.setAllowFileAccess(true)
s.setAllowContentAccess(true)
s.setAppCacheEnabled(true)
s.setCacheMode(WebSettings.LOAD_DEFAULT)
s.setUseWideViewPort(true)
s.setLoadWithOverviewMode(true)
s.setBuiltInZoomControls(true)
s.setDisplayZoomControls(false)
s.setDatabaseEnabled(true)

-- 默认 UA（Safari）
s.setUserAgentString(
"Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
)

-- 添加 JS 接口
local bridge = {}
function bridge.setUserAgent(ua)
  local s = wv.getSettings()
  s.setUserAgentString(tostring(ua))
  print("UA set to: "..tostring(ua))
end
function bridge.exitApp()
  doExit()
end
wv.addJavascriptInterface(bridge, "lua")

function doExit()
  activity.finish()
end

wv.setWebViewClient{
  shouldOverrideUrlLoading=function(view, url)
    url = tostring(url)

    -- 特殊协议：js://exit
    if url == "js://exit" then
      doExit()
      return true
    end

    -- 拦截百度协议
    if url:find("^baiduboxlite://") or url:find("^baiduboxapp://") then
      Toast.makeText(activity, "已忽略百度App链接: "..url, Toast.LENGTH_SHORT).show()
      return true
    end

    -- 允许 http/https 请求
    if url:find("^https?://") then
      view.loadUrl(string.format([[
        javascript:(function(){
          var browser=document.getElementById("browser");
          if(browser){
            browser.src="%s";
            var addr=document.getElementById("addressBar");
            if(addr) addr.value="%s";
          }
          var btn=document.getElementById('exit-button');
          if(btn && !btn.__bound){
            btn.__bound=true;
            btn.addEventListener('click',function(){
              location.href='js://exit';
            });
          }
        })()
      ]], url, url))
      return true
    end

    Toast.makeText(activity, "不支持的链接: "..url, Toast.LENGTH_SHORT).show()
    return true
  end,

  -- 退出
  onPageFinished=function(view, url)
    view.loadUrl([[
      javascript:(function(){
        var btn=document.getElementById('exit-button');
        if(btn && !btn.__bound){
          btn.__bound=true;
          btn.addEventListener('click',function(){
            location.href='js://exit';
          });
        }
      })()
    ]])
  end
}

-- 加载主页
wv.loadUrl("file://"..this.getLuaDir().."/index.html")
