var SelectedTextPreprocessor = function() {};
SelectedTextPreprocessor.prototype = {
    run: function(args) {
        args.completionFunction({
            "url": document.URL,
            "title": document.title,
            "selectedText": window.getSelection().toString()
        });
    }
};
window.ExtensionPreprocessingJS = new SelectedTextPreprocessor();
