function train_object(cls_id,annot)
VOCopts.classes={...
    'aeroplane'
    'bicycle'
    'bird'
    'boat'
    'bottle'
    'bus'
    'car'
    'cat'
    'chair'
    'cow'
    'diningtable'
    'dog'
    'horse'
    'motorbike'
    'person'
    'pottedplant'
    'sheep'
    'sofa'
    'train'
    'tvmonitor'};
fclose all
test_set='test';
cls=VOCopts.classes{cls_id};
model=pascal_train(cls,1);
[boxes1, boxes2] = pascal_test(cls, model, test_set, annot);
ap = pascal_eval(cls, boxes1, test_set, annot);
fprintf('session %s, class %s, ap %f\n',annot,cls,ap);