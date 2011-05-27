function cns(page) {
    if ((navigator.appVersion.indexOf("Linux") != -1) && (typeof cnspathlin == 'function')) {
        window.location = cnspathlin() + "/" + page;
    } else if ((navigator.appVersion.indexOf("Win") != -1) && (typeof cnspathwin == 'function')) {
        window.location = cnspathwin() + "/" + page;
    } else if ((navigator.appVersion.indexOf("Mac") != -1) && (typeof cnspathmac == 'function')) {
        window.location = cnspathmac() + "/" + page;
    } else {
        window.location = "http://cbcl.mit.edu/jmutch/cns/doc/" + page;
    }
}
