def probe_str(probe) {
    probeParts = probe.split("\\.")
    if (probeParts.size() > 1) {
        imStr = probeParts[1]
        if (imStr.length() <= 4)
            return ''   // 3A data, no probe index
        else
            return imStr.substring(4)
    } else
        return ''
}

def probe_name(probe) {
    probeParts = probe.split("\\.")
    if (probeParts.size() > 1) {
        probeParts[0] + "_" + probeParts[1]
    } else
        probe
}

def input_config(configDir, probeName) {
    file("${configDir}/${probeName}-input.json")
}

def output_config(configDir, probeName) {
    file("${configDir}/${probeName}-output.json")
}

def 