def read_json(cf) {
    def jsonSlurper = new groovy.json.JsonSlurper()
    return jsonSlurper.parse(file(cf))
}

def write_json(data, cf) {
    def json_str = groovy.json.JsonOutput.toJson(data)
    def json_beauty = groovy.json.JsonOutput.prettyPrint(json_str)
    cf.write(json_beauty)
}

def index_channel(c) {
    c.reduce([ 0, [] ]) { accum, elem ->
        def indexed_elem = [accum[0], elem]
        [ accum[0]+1, accum[1]+[indexed_elem] ]
    } | flatMap { it[1] }
}
