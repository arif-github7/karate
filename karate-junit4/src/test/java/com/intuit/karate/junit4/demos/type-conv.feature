Feature: convert between json, xml and string

Scenario: multi-line text
# although the value starts with '{' it is not parsed as JSON, and line-feeds are retained
* text query =
"""
{
  hero(name: "Luke Skywalker") {
    height
    mass
  }
}
"""
* match query == read('query.txt')

Scenario Outline: multi-line text in a scenario outline
* text query =
"""
{
  hero(name: "<name>") {
    height
    mass
  }
}
"""
* match query == read('query.txt')

Examples:
| name           |
| Luke Skywalker |

Scenario: multi-line string expression
# this is normally never required since you can use replace
* def name = 'Luke Skywalker'
* string query = '{\n  hero(name: "' + name + '") {\n    height\n    mass\n  }\n}'
* match query == read('query.txt')

Scenario: string to json
# this would be of type string (not JSON)
* def strVar = '{ "foo": "bar" }'
* json jsonVar = strVar
* match jsonVar == { foo: 'bar' }

Scenario: json to string
* def jsonVar = { foo: 'bar' }
* string strVar = jsonVar
* assert strVar == '{"foo":"bar"}'

Scenario: string to xml
* def strVar = '<root><foo>bar</foo></root>'
* xml xmlVar = strVar
* match xmlVar == <root><foo>bar</foo></root>

Scenario: xml to string (incorrect)
* def xmlVar = <root><foo>bar</foo></root>
# the parentheses forces evaluation as javascript and converts the xml to a map
* string strVar = (xmlVar)
# because of karate's internal map-like default representation, this happens. see 'xmlstring' below
* match strVar == '{"root":{"foo":"bar"}}'

Scenario: xml to string
* def xmlVar = <root><foo>bar</foo></root>
# note that the keyword here is 'xmlstring' not 'string'
* xmlstring strVar = xmlVar
* match strVar == '<root><foo>bar</foo></root>'

Scenario: xml to json
* def xmlVar = <root><foo>bar</foo></root>
* json jsonVar = xmlVar
* match jsonVar == { root: { foo: 'bar' } }

Scenario: json to xml
* def jsonVar = { root: { foo: 'bar' } }
* xml xmlVar = jsonVar
* match xmlVar == <root><foo>bar</foo></root>

Scenario: xml with attributes
* def xmlVar = <root><foo fizz="buzz">bar</foo></root>
* json jsonVar = xmlVar
# it ain't pretty but this is how karate converts xml to a map-like object internally for parity with json
* match jsonVar == { root: { foo: { _ : 'bar', @: { fizz: 'buzz' }}}}
# which means that json can be used instead of xpath
* match jsonVar $.root.foo._ == 'bar'
* match jsonVar $.root.foo.@ == { fizz: 'buzz' }
* match jsonVar $.root.foo.@.fizz == 'buzz'
* match jsonVar $..foo.@.fizz == ['buzz']
* match jsonVar $..@.fizz contains 'buzz'
* match jsonVar $..foo.@ contains { fizz: 'buzz' }

Scenario: xml with namespaces
* def xmlVar = <ns1:root xmlns:ns1="http://foo.com" xmlns:ns2="http://bar.com"><ns2:foo fizz="buzz" ping="pong">bar</ns2:foo></ns1:root>
* json jsonVar = xmlVar
* match jsonVar == 
"""
{ 
  "ns1:root": {
    "@": { "xmlns:ns1": "http://foo.com", "xmlns:ns2": "http://bar.com" },
    "_": { 
      "ns2:foo": { 
        "_": "bar", 
        "@": { "fizz": "buzz", "ping": "pong" } 
      } 
    }     
  }
}
"""
* match jsonVar $.ns1:root..ns2:foo.@ == [{ fizz: 'buzz', ping: 'pong' }]
* match jsonVar $..ns2:foo.@ == [{ fizz: 'buzz', ping: 'pong' }]
* match jsonVar $..ns2:foo.@ contains { fizz: 'buzz', ping: 'pong' }
* match jsonVar $..ns2:foo.@ contains only { fizz: 'buzz', ping: 'pong' }
* match each jsonVar $..ns2:foo.@ contains { ping: 'pong' }

Scenario: java pojo to json
* def className = 'com.intuit.karate.junit4.demos.SimplePojo'
* def Pojo = Java.type(className)
* def pojo = new Pojo()
* json jsonVar = pojo
* match jsonVar == { foo: null, bar: 0 }
* def testJson = { foo: 'hello', bar: 5 }
* def testPojo = karate.toBean(testJson, className)
* assert testPojo.foo == 'hello'
* assert testPojo.bar == 5

Scenario: java pojo to xml
* def Pojo = Java.type('com.intuit.karate.junit4.demos.SimplePojo')
* def pojo = new Pojo()
* xml xmlVar = pojo
* match xmlVar == <root><foo></foo><bar>0</bar></root>

Scenario: json manipulation using string-replace
* def data =
"""
{
  foo: '<foo>',
  bar: { hello: '<bar>'}
}
"""
# replace is convenient sometimes because you don't need to worry about complex nested paths
* replace data
    | token | value |
    | foo   | 'bar' |
    | bar   | 'baz' |

# don't forget to cast back to json though
* json data = data
* match data == { foo: 'bar', bar: { hello: 'baz' } }