 fea = rand(50,70);
 gnd = [ones(10,1);ones(15,1)*2;ones(10,1)*3;ones(15,1)*4];
 options = [];
 options.intraK = 5;
 options.interK = 40;
 options.Regu = 1;
 [sb,sc,eigvector, eigvalue] = MFA(gnd, options, fea);
 Y = fea*eigvector;