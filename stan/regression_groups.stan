// Normal linear regression with an intercept for each group:
//   y ~ normal(alpha + a[group] + X * beta, sigma),  a ~ normal(0, tau)
//
// The R and Python projects keep identical copies of this file.
//
// centered = 1 samples a directly. centered = 0 samples a standardized
// offset z and sets a = tau * z, the non-centered form. Both describe the same
// model. They differ in how hard the posterior is for the sampler, which the
// diagnostics notebook shows.
data {
  int<lower=0> N;
  int<lower=0> K;
  int<lower=1> J;
  matrix[N, K] X;
  vector[N] y;
  array[N] int<lower=1, upper=J> group;

  real alpha_mean;
  real<lower=0> alpha_sd;
  vector[K] beta_mean;
  vector<lower=0>[K] beta_sd;
  real<lower=0> sigma_rate;
  real<lower=0> tau_rate;

  int<lower=0, upper=1> centered;
}
parameters {
  real alpha;
  vector[K] beta;
  real<lower=0> sigma;
  real<lower=0> tau;
  vector[J] z;
}
transformed parameters {
  vector[J] a = centered ? z : tau * z;
}
model {
  alpha ~ normal(alpha_mean, alpha_sd);
  beta ~ normal(beta_mean, beta_sd);
  sigma ~ exponential(sigma_rate);
  tau ~ exponential(tau_rate);
  if (centered) {
    z ~ normal(0, tau);
  } else {
    z ~ std_normal();
  }
  y ~ normal_id_glm(X, alpha + a[group], beta, sigma);
}
