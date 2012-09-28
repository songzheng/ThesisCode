function [test_res_age, test_res_gender] = AgeGenderEvaluationTestRegression(feature, model)

test_res_age = LinearRegressionTest(feature, model.agemodel);
test_res_gender = LinearRegressionTest(feature, model.gendermodel);

