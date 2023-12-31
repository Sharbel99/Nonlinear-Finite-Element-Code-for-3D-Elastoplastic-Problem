function [ElemK, ElemF,Fp1,bep1,qp1,alphap1,C_epp1,stress,strain] = Elast3d_Elem(xl,mateprop,nel,ndf,ul,F,be,q,alpha)
%
% Copyright (C) Arif Masud and Tim Truster
%
% Subroutine to compute stiffness matrix and force vector for linear
% 2-dimensional elasticity element. Element currently supports bilinear
% quadrilateral elements with the following node and shape function
% labelling scheme:
%
%  (-1, 1)  4 -------------- 3 ( 1, 1)
%           |       s        |
%           |       ^        |
%           |       |        |
%           |       .-> r    |
%           |                |
%           |                |
%  (-1,-1)  1 -------------- 2 ( 1,-1)
%
% Element local coordinates (r,s) are defined by a coordinate axis with the
% origin at the center of the element; the corners of the element have
% local coordinate values as shown in the figure.
%
% Definitions for input:
%
%   xl:              = local array containing (x,y) coordinates of nodes
%                      forming the element; format is as follows:
%                          Nodes    |        n1  n2  n3  n4
%                          x-coord  |  xl = [x1  x2  x3  x4
%                          y-coord  |        y1  y2  y3  y4];
%
%   mateprop:        = vector of material properties:
%                          mateprop = [E v t]; 
%                                   = [(Young's Modulus) (Poisson's Ratio)
%                                      (thickness)];
%
%   nel:             = number of nodes on current element (4)
%
%   ndf:             = max number of DOF per node (2)
%
%   ndm:             = space dimension of mesh (2)
%
%   PSPS:            = flag for plane stress ('s') or plane strain ('n')
%
% Definitions for output:
%
%   ElemK:           = element stiffness matrix containing stiffness
%                      entries in the following arrangement, where
%                      wij corresponds to weighting function (i), coordinate
%                      direction (j), and ukl corresponds to displacement
%                      function (k), coordinate direction (l):
%                                 u1x  u1y  u2x  u2y  u3x  u3y  u4x  u4y
%                      w1x  ElemK[ .    .    .    .    .    .    .    .
%                      w1y         .    .    .    .    .    .    .    .
%                      w2x         .    .    .    .    .    .    .    .
%                      w2y         .    .    .    .    .    .    .    .
%                      w3x         .    .    .    .    .    .    .    .
%                      w3y         .    .    .    .    .    .    .    .
%                      w4x         .    .    .    .    .    .    .    .
%                      w4y         .    .    .    .    .    .    .    . ];
%
%   ElemF:           = element force vector containing force entries in the
%                      following arrangement:
%                      w1x  ElemF[ . 
%                      w1y         . 
%                      w2x         . 
%                      w2y         . 
%                      w3x         . 
%                      w3y         . 
%                      w4x         . 
%                      w4y         . ];                      
%
% Definitions of local constants:
%
%   nst:             = size of element arrays (ndf*nel)
%
%



% Set Material Properties

mu1    = mateprop(1);
kappa  = mateprop(2);
sigma_y = mateprop(3);
K1 = mateprop(4);
H = mateprop(5);

ul_elem = reshape(ul,ndf*nel,1);

delta = eye(3);

% Initialize Matrix and Vector

nst = nel*ndf;
ElemK = zeros(nst);
ElemF = zeros(nst,1);

% Load Guass Integration Points

if nel == 4
    lint = 4; 
else
    lint = 8; 
end

%epsilon = zeros(lint,6);

% Loop over integration points
for l = 1:lint

        if nel == 4
            [Wgt,r,s,t] =  intpntt3(l,lint,0);
        else
            [Wgt,r,s,t] =  intpntq3(l,lint,0);
        end

        % Evaluate local basis functions at integration point
        shp = shpl_3d(r,s,t,nel);

        % Evaluate first derivatives of basis functions at int. point
        [Qxy_ref, Jdet_ref] = shpg_3d(shp,xl,nel);
        [Qxy, Jdet] = shpg_3d(shp,xl+ul,nel);

        % Form B matrix
        if nel == 4
        Bmat = [Qxy(1,1) 0        0        Qxy(1,2) 0        0       ,...
                Qxy(1,3) 0        0        Qxy(1,4) 0        0       ;...
                0        Qxy(2,1) 0        0        Qxy(2,2) 0       ,...
                0        Qxy(2,3) 0        0        Qxy(2,4) 0       ;...
                0        0        Qxy(3,1) 0        0        Qxy(3,2),...
                0        0        Qxy(3,3) 0        0        Qxy(3,4);...
                Qxy(2,1) Qxy(1,1) 0        Qxy(2,2) Qxy(1,2) 0       ,...
                Qxy(2,3) Qxy(1,3) 0        Qxy(2,4) Qxy(1,4) 0       ;...
                0        Qxy(3,1) Qxy(2,1) 0        Qxy(3,2) Qxy(2,2),...
                0        Qxy(3,3) Qxy(2,3) 0        Qxy(3,4) Qxy(2,4);...
                Qxy(3,1) 0        Qxy(1,1) Qxy(3,2) 0        Qxy(1,2),...
                Qxy(3,3) 0        Qxy(1,3) Qxy(3,4) 0        Qxy(1,4)];
        else
        Bmat = [Qxy(1,1) 0        0        Qxy(1,2) 0        0       ,...
                Qxy(1,3) 0        0        Qxy(1,4) 0        0       ,...
                Qxy(1,5) 0        0        Qxy(1,6) 0        0       ,...
                Qxy(1,7) 0        0        Qxy(1,8) 0        0       ;...
                0        Qxy(2,1) 0        0        Qxy(2,2) 0       ,...
                0        Qxy(2,3) 0        0        Qxy(2,4) 0       ,...
                0        Qxy(2,5) 0        0        Qxy(2,6) 0       ,...
                0        Qxy(2,7) 0        0        Qxy(2,8) 0       ;...
                0        0        Qxy(3,1) 0        0        Qxy(3,2),...
                0        0        Qxy(3,3) 0        0        Qxy(3,4),...
                0        0        Qxy(3,5) 0        0        Qxy(3,6),...
                0        0        Qxy(3,7) 0        0        Qxy(3,8);...
                Qxy(2,1) Qxy(1,1) 0        Qxy(2,2) Qxy(1,2) 0       ,...
                Qxy(2,3) Qxy(1,3) 0        Qxy(2,4) Qxy(1,4) 0       ,...
                Qxy(2,5) Qxy(1,5) 0        Qxy(2,6) Qxy(1,6) 0       ,...
                Qxy(2,7) Qxy(1,7) 0        Qxy(2,8) Qxy(1,8) 0       ;...
                0        Qxy(3,1) Qxy(2,1) 0        Qxy(3,2) Qxy(2,2),...
                0        Qxy(3,3) Qxy(2,3) 0        Qxy(3,4) Qxy(2,4),...
                0        Qxy(3,5) Qxy(2,5) 0        Qxy(3,6) Qxy(2,6),...
                0        Qxy(3,7) Qxy(2,7) 0        Qxy(3,8) Qxy(2,8);...
                Qxy(3,1) 0        Qxy(1,1) Qxy(3,2) 0        Qxy(1,2),...
                Qxy(3,3) 0        Qxy(1,3) Qxy(3,4) 0        Qxy(1,4),...
                Qxy(3,5) 0        Qxy(1,5) Qxy(3,6) 0        Qxy(1,6),...
                Qxy(3,7) 0        Qxy(1,7) Qxy(3,8) 0        Qxy(1,8)];           
        end
        
        
        Gradu=[ Qxy_ref(1,:)*ul(1,:)'  Qxy_ref(2,:)*ul(1,:)'  Qxy_ref(3,:)*ul(1,:)'
                Qxy_ref(1,:)*ul(2,:)'  Qxy_ref(2,:)*ul(2,:)'  Qxy_ref(3,:)*ul(2,:)'
                Qxy_ref(1,:)*ul(3,:)'  Qxy_ref(2,:)*ul(3,:)'  Qxy_ref(3,:)*ul(3,:)'];
        Fp1(:,:,l)    = eye(3)+Gradu;
        
        fp1     = Fp1(:,:,l)*inv(F(:,:,l));
        fp1bar = det(fp1)^(-1/3).*fp1;
        
        bep1_tr      = fp1bar*be(:,:,l)*fp1bar';
        trbep1_tr    = bep1_tr(1,1) + bep1_tr(2,2)+ bep1_tr(3,3);
        devbep1_tr = bep1_tr - 1./3.*trbep1_tr.*eye(3);
        
        sp1_tr      = mu1.*devbep1_tr;
        qp1_tr      = fp1bar*q(:,:,l)*fp1bar';
        alphap1_tr = alpha(l);
        
        zetap1_tr         = sp1_tr - qp1_tr;
        zetap1_tr_norm = norm (zetap1_tr,'fro');
        
        f_trial              = zetap1_tr_norm - sqrt(2/3)*(sigma_y + K1*alphap1_tr);
        
        if f_trial<=0
            
            bep1(:,:,l) = bep1_tr;
            sp1          = sp1_tr;
            qp1(:,:,l)  = qp1_tr;
            alphap1(l) = alphap1_tr;
            
        else
            
            delta_gamma = f_trial / ( 2/3* ((H+mu1)*trbep1_tr+K1));
            np1              =  zetap1_tr./ zetap1_tr_norm;
            
            sp1          = sp1_tr - delta_gamma.*2./3.*mu1.*trbep1_tr.*np1;
            qp1(:,:,l)  = qp1_tr + delta_gamma.*2./3.*H.*trbep1_tr.*np1;
            alphap1(l) = alphap1_tr + sqrt(2/3)*delta_gamma; 
            bep1(:,:,l) = sp1./mu1 + trbep1_tr./3.*eye(3);
            
        end
        
        be_bar = bep1(:,:,l);
        Je = det(Fp1(:,:,l));
       
        strain_matrix = 0.5.*(Fp1(:,:,l)'*Fp1(:,:,l)-eye(3));
        
        Up   = 0.5*kappa*(Je-1/Je);
        Upp = 0.5*kappa*(1+1/Je^2);
        
        taw_matrix    = Up.*Je.*eye(3) + sp1;
        stress_matrix = taw_matrix./Je;
        
        stress(1:6,l)   = [stress_matrix(1,1); stress_matrix(2,2); stress_matrix(3,3); stress_matrix(1,2); stress_matrix(2,3); stress_matrix(1,3)];
        strain(1:6,l)    = [strain_matrix(1,1); strain_matrix(2,2); strain_matrix(3,3); strain_matrix(1,2); strain_matrix(2,3); strain_matrix(1,3)];
       
         for a=1:3
           for b=1:3
             for c=1:3
                for d=1:3
                   I4=0.5*(delta(a,c)*delta(b,d)+delta(a,d)*delta(b,c));
                   C_material(a,b,c,d) = (Upp*Je + Up)*delta(a,b)*delta(c,d) - 2*Up*I4 - 2/3*mu1/Je*(be_bar(a,b)*delta(c,d) + delta(a,b)*be_bar(c,d)) ...
                                              + 1/3*mu1/Je*trbep1_tr*(2/3*delta(a,b)*delta(c,d) + 2*I4);
                   C_stress(a,b,c,d) = delta(a,c)*stress_matrix(b,d);
                end
             end
           end
         end
            
         C_tensor = C_material + C_stress;
       
        C_matrix = [C_tensor(1,1,1,1)  C_tensor(1,1,2,2)  C_tensor(1,1,3,3)  C_tensor(1,1,1,2)  C_tensor(1,1,2,3)  C_tensor(1,1,1,3)
                     C_tensor(2,2,1,1)  C_tensor(2,2,2,2)  C_tensor(2,2,3,3)  C_tensor(2,2,1,2)  C_tensor(2,2,2,3)  C_tensor(2,2,1,3)
                     C_tensor(3,3,1,1)  C_tensor(3,3,2,2)  C_tensor(3,3,3,3)  C_tensor(3,3,1,2)  C_tensor(3,3,2,3)  C_tensor(3,3,1,3)
                     C_tensor(1,2,1,1)  C_tensor(1,2,2,2)  C_tensor(1,2,3,3)  C_tensor(1,2,1,2)  C_tensor(1,2,2,3)  C_tensor(1,2,1,3)
                     C_tensor(2,3,1,1)  C_tensor(2,3,2,2)  C_tensor(2,3,3,3)  C_tensor(2,3,1,2)  C_tensor(2,3,2,3)  C_tensor(2,3,1,3)
                     C_tensor(1,3,1,1)  C_tensor(1,3,2,2)  C_tensor(1,3,3,3)  C_tensor(1,3,1,2)  C_tensor(1,3,2,3)  C_tensor(1,3,1,3)];
            
        % Update integration weighting factor
        W = Wgt*Jdet;
        ElemKi=zeros(ndf*nel);
        for a=1:nel
           for b=1:nel
               for i=1:ndf
                    for j=1:ndf
                        for k=1:ndf
                          for l1=1:ndf
                              p=ndf*(a-1)+i;
                              q1=ndf*(b-1)+k;
                              ElemKi(p,q1)= ElemKi(p,q1)+Qxy(j,a)*C_tensor(i,j,k,l1)*Qxy(l1,b);
                          end
                        end
                    end
                end
            end
        end  
        ElemK = ElemK + W*ElemKi;
        ElemF = ElemF + W*Bmat'*stress(1:6,l);
        C_epp1(:,:,l) = C_matrix;

end %je