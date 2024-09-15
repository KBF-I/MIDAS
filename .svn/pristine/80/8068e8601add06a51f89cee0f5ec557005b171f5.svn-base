function [vert, horz] = wahr(disc_rad,xi,love_h,love_l); 
% a function to compute vertical and horizontal crustal motion... 
% ...for a disc load, inspired by Figure 1 of Wahr et al., 2013. 
% 
% usage: 
%		[vert, horz] = wahr(disc_rad,xi,love_h,love_l); 
%		
%		vert = vertical crustal motion [m] 
%		horz = horizontal crustal motion [m] 
%		disc_rad = disc radius [m] => set to 20 km to replicate the Wahr experiment. 
%		xi = grid points along the distance away from the disc center [m] 
%		love_h = load Love numbers h for the vertical crustal motion. 
%		love_l = load Love numbers l for the horizontal crustal motion. 
%		

	disc_rad = disc_rad/1000; % km 
	% compute P(x), dP(x)/dx, d2P(x)/dx2
	%---------------------------------------------------------------------
	% compute p_value 
	theta=km2deg(xi/1000)';
	ang = theta/180*pi; 
	alpha=cos(ang);
	m=length(alpha);
	n=length(love_h)-1; 
	p_value = p_polynomial_value(m,n,alpha);
	p_prime = p_polynomial_prime(m,n,alpha);
	%---------------------------------------------------------------------
	nn=[0:n];
	nn_plus_1=nn+1; 

	% disc radius in degree 
	disc_rad = km2deg(disc_rad)/180*pi; 
	tau=zeros(size(love_h)); 
	tau(1) = 0.5*(1-cos(disc_rad)); % tau_0 
	p_value_disc = p_polynomial_value(1,n+1,cos(disc_rad));
	p_prime_disc = p_polynomial_prime(1,n,cos(disc_rad));
	for jj=2:n+1
		nnn = jj-1; 
		tau(jj) = 0.5 * (p_value_disc(jj-1) - p_value_disc(jj+1)); 
	end

	const=zeros(size(love_h)); 
	for jj=1:n+1
		const(jj) = 1/(2*(jj-1)+1); 
	end

	disc=sum(bsxfun(@times,p_value,tau'),2); 

	g1 = -sum(bsxfun(@times,p_value,(tau.*love_h.*const)'),2); 
	g5 = -sum(bsxfun(@times,-sin(ang),bsxfun(@times,p_prime,(tau.*love_l.*const)')),2); 

	% coeff 
	coeff = 1000*4*pi*(6.67408*10^-11)*(6.3781*10^6)/9.81; 

	% vertical and horizontal solutions
	vert = g1*coeff; % m 
	horz = g5*coeff; % m 

