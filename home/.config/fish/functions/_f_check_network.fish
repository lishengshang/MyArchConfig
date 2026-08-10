function _f_check_network -d "Check network connectivity for f"
    curl -sI --connect-timeout 2 "http://captive.apple.com/hotspot-detect.html" >/dev/null 2>&1
    return $status
end
