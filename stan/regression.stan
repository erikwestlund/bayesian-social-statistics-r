// Normal linear regression: y ~ normal(alpha + X * beta, sigma)
//
// The R and Python projects keep identical copies of this file.
//
// prior = 0: flat priors. alpha, beta, and log(sigma) are uniform over the
//            real line, so the prior density is proportional to 1 / sigma.
//            Under this prior each coefficient's marginal posterior is the
//            t distribution that gives the OLS confidence interval, so the
//            central posterior intervals match the OLS intervals. The priors
//            are improper: the posterior is proper only when X has full
//            column rank, the residuals are not all 0, and N > K + 1, and
//            prior_only must be 0.
// prior = 1: normal priors on alpha and beta, exponential prior on sigma,
//            with the means and SDs given as data.
// prior_only = 1 skips the likelihood, so the draws come from the prior.
// predict = 1 adds y_rep, one replicated outcome per observation per draw,
//            and log_lik, each observation's log likelihood.
data {
  int<lower=0> N;
  int<lower=0> K;
  matrix[N, K] X;
  vector[N] y;

  int<lower=0, upper=1> prior;
  real alpha_mean;
  real<lower=0> alpha_sd;
  vector[K] beta_mean;
  vector<lower=0>[K] beta_sd;
  real<lower=0> sigma_rate;

  int<lower=0, upper=1> prior_only;
  int<lower=0, upper=1> predict;
}
transformed data {
  if (prior_only && !prior) {
    reject("prior_only needs proper priors: set prior = 1");
  }
}
parameters {
  real alpha;
  vector[K] beta;
  real<lower=0> sigma;
}
model {
  if (prior) {
    alpha ~ normal(alpha_mean, alpha_sd);
    beta ~ normal(beta_mean, beta_sd);
    sigma ~ exponential(sigma_rate);
  } else {
    // Uniform on log(sigma): the density of sigma is proportional to 1 / sigma
    target += -log(sigma);
  }
  if (!prior_only) {
    y ~ normal_id_glm(X, alpha, beta, sigma);
  }
}
generated quantities {
  array[predict ? N : 0] real y_rep;
  vector[predict ? N : 0] log_lik;
  if (predict) {
    vector[N] mu = alpha + X * beta;
    y_rep = normal_rng(mu, sigma);
    for (n in 1:N) {
      log_lik[n] = normal_lpdf(y[n] | mu[n], sigma);
    }
  }
}
