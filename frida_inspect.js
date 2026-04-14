// Inspect CCUIContinuousSliderView ivars
var cls = ObjC.classes.CCUIContinuousSliderView;
var ivars = cls.$ivars;
console.log("CCUIContinuousSliderView ivars: " + JSON.stringify(Object.keys(ivars)));

// Check CCUICAPackageDescription
var cls2 = ObjC.classes.CCUICAPackageDescription;
if (cls2) {
    console.log("CCUICAPackageDescription methods: " + JSON.stringify(Object.keys(cls2.$ownMethods)));
}

// Check CCUIBaseSliderView ivars
var cls3 = ObjC.classes.CCUIBaseSliderView;
console.log("CCUIBaseSliderView ivars: " + JSON.stringify(Object.keys(cls3.$ivars)));
