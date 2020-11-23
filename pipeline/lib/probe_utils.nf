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

def config_file(configDir, probeName, step, type) {
    file("${configDir}/${probeName}-${step}-${type}.json")
}

def filter_config(config, fields) {
    return config.subMap(fields)
}

def read_config(cf) {
    jsonSlurper = new groovy.json.JsonSlurper()
    return jsonSlurper.parse(cf)
}

def write_config(data, cf) {
    json_str = groovy.json.JsonOutput.toJson(data)
    json_beauty = groovy.json.JsonOutput.prettyPrint(json_str)
    cf.write(json_beauty)
}
