import QtQml

QtObject {
    property string formatterName: "base"

    function serialize(evaluation, request) {
        console.warn("BaseFormatter.serialize() not implemented for", formatterName)
        return ({})
    }
}
