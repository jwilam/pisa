# ============================================================
# network_ega_pisa_design.R   (v3.2 - design-based + informative network figure)
# ------------------------------------------------------------
# PISA 2025 | Exploratory Graph Analysis with complex-sample inference
#
# Pipeline
#   1. Load STU data + country lookup + variable metadata
#   2. Country (+ optional demographic) filters
#   3. Build nodes: PISA WLE indices / constructs + item composites + PV nodes
#   4. ONE listwise analysis sample + attrition diagnostics
#   5. (optional) UVA redundancy check on NON-PV nodes (PV protected)
#   6. Design-based estimation: 10 PVs x (final + 80 Fay-BRR weights)
#      -> weighted, covariate-adjusted correlations, Fisher-z pooled,
#      Fay-BRR + Rubin variance; node predictability R2
#   7. EBIC sample size: nominal / Kish / design-effect adjusted
#   8. EGA on the pooled matrix (seeded) + network loadings + TEFI
#   9. Sensitivity: EBIC n-mode x community algorithm (ARI + TEFI)
#  10. Stability: school-cluster bootstrap within strata (PVs rotated)
#      -> item stability, modal/runner-up membership, core consistency
#  11. Publication tables (CSV), figures (PDF/PNG), methods summary
#
# v3.2 fixes
#   - Pie key layer: fill length error (caused blank Fig1) fixed
#   - Plots are fully rendered off-screen BEFORE saving; on failure the real
#     error is printed, the EGAnet fallback is used, and no blank files remain
#   - Runner-up community = best community after the MODAL one (was wrong
#     when modal != assigned); Modal_differs flag added
#
# Requires R >= 4.1. Edit the CONFIGURATION block only.
# ============================================================

suppressPackageStartupMessages({
  library(EGAnet)
  library(igraph)
  library(haven)
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(tibble)
  library(ggplot2)
})
# Optional: Matrix (PD repair), clue (Hungarian alignment)
# Network figure: ggraph, tidygraph, ggrepel, ggforce, scales
#                 (+ concaveman for concave hulls, graphlayouts for "stress")

# ============================================================
# =====================  CONFIGURATION  ======================
# ============================================================

## ---- File paths --------------------------------------------
RDS_DIR  <- "rds_data"
CSV_DIR  <- "csv_data"
STU_DATA_FILE   <- file.path(RDS_DIR, "CY09_MS_STU_IDB2_HKG.rds")
LOOKUP_FILE     <- file.path(RDS_DIR, "cntry_fcnt.rds")
STU_VAR_FILE    <- file.path(CSV_DIR, "CY09_MS_STU_IDB2.csv")
CONSTRUCTS_FILE <- file.path(CSV_DIR, "constructs.csv")

## ---- Countries / demographic filters -----------------------
FOCUS_COUNTRIES <- c("Hong Kong (China)")
DEMO_FILTERS    <- list()   # e.g. list(ST004D01D = c("1"))

## ---- Domains (PV suffixes) ---------------------------------
SELECTED_DOMAINS <- c("SCIE")

## ---- Node variables ----------------------------------------
NET_SOURCE <- "index"   # "index" or "construct"

SELECTED_INDICES <- c(
  "CURIO", "BELONG", "TEACHSUP", "COGACSC", "SCIECOLLR", "JOYSCIE",
  "EFFSCIE", "STBELSCIE", "PERSEV", "ENPROBS", "COGABIL", "GOALSET",
  "SELFREG", "ENGSCIPR"
)
SELECTED_CONSTRUCTS <- character(0)
CONSTRUCT_MIN_PROP  <- 0.5   # min. proportion of valid items for a construct score

## ---- Extra item-composite nodes ----------------------------
INCLUDE_EXTRA_NODES <- TRUE
EXTRA_NODES <- list(
  GROWTHMND = list(label = "Growth mindset",
                   items = c("ST420Q01DA", "ST420Q02DA"),
                   reversed = c(TRUE, TRUE), max_scale = 4,
                   min_items = 2),          # both items required
  VALSCHL   = list(label = "Value of school",
                   items = c("ST324Q10JA", "ST324Q11JA", "ST324Q13JA"),
                   reversed = c(TRUE, TRUE, FALSE), max_scale = 4,
                   min_items = 2)           # >= 2 of 3 items required
)

## ---- Covariate adjustment ----------------------------------
# Network is estimated CONDITIONAL on these variables (they are partialled
# out and are NOT drawn as nodes). Use character(0) for no adjustment.
# "FEMALE" is a built-in dummy from ST004D01D (1 = female, 0 = male, other = NA).
# default ADJUST_FOR <- c("ESCS")
ADJUST_FOR <- character(0)


## ---- Complex-sample design ---------------------------------
FINAL_WT      <- "W_FSTUWT"
REP_WT_PREFIX <- "W_FSTURWT"
N_REP         <- 80L
FAY_K         <- 0.5
SCHOOL_ID     <- "CNTSCHID"
STRATUM_VAR   <- "STRATUM"
WLE_ABS_MAX   <- 15     # |WLE| above this is treated as a stray missing code

## ---- UVA (redundancy) --------------------------------------
NET_USE_UVA    <- FALSE
NET_UVA_METHOD <- "MBR"   # EGAnet 1.x only (ignored by 2.x)
NET_UVA_CUTOFF <- 0.25

## ---- EGA ---------------------------------------------------
NET_MODEL      <- "glasso"
NET_ALGORITHM  <- "leiden"   # walktrap / louvain / leiden
NET_UNI_METHOD <- "louvain"
LEIDEN_ARGS    <- list(objective_function = "modularity")
EGA_SEED       <- 42
EBIC_N_MODE    <- "nominal"   # nominal / kish / deff

RUN_SENSITIVITY <- TRUE
SENS_N_MODES    <- c("nominal", "kish", "deff")
SENS_ALGORITHMS <- c("walktrap", "louvain", "leiden")

## ---- Stability ---------------------------------------------
RUN_BOOTEGA         <- TRUE
BOOT_TYPE           <- "cluster"  # cluster (design-based) / parametric / both
NET_BOOT_ITER       <- 500
NET_BOOT_SEED       <- 42
ITEM_STAB_THRESHOLD <- 0.70

## ---- Inference ---------------------------------------------
CI_LEVEL  <- 0.95
FDR_ALPHA <- 0.05

## ---- Output ------------------------------------------------
OUTPUT_DIR      <- "network_ega_output"
SAVE_PLOT       <- TRUE
PLOT_FORMATS    <- c("pdf", "png")   # add "tiff" for some journals
PLOT_DPI        <- 600
PLOT_SHOW_TITLE <- TRUE              # FALSE for journal figures (title in caption)

## ---- Network plot aesthetics -------------------------------
PLOT_ENGINE      <- "ggraph"          # "ggraph" or "ega"
PLOT_FULL_LABELS <- TRUE

# Node SIZE: "constant" | "item_stability" | "predictability" | "strength"
PLOT_NODE_SIZE_BY      <- "constant"
PLOT_NODE_RADIUS       <- 0.040            # constant radius (fraction of layout span)
PLOT_NODE_RADIUS_RANGE <- c(0.026, 0.050)  # used when size is mapped (area-scaled)

# Node RING: "predictability" | "item_stability" | "none"
PLOT_NODE_RING          <- "predictability"
PLOT_RING_WIDTH         <- 0.013
PLOT_RING_VALUE_IN_NODE <- TRUE

# Bridge (unstable) nodes: item stability < ITEM_STAB_THRESHOLD
#   "pie"  = split fill by bootstrap community membership
#   "halo" = dashed halo only | "both" | "none"
PLOT_BRIDGE_STYLE    <- "pie"
# Hull (shaded region) membership:
#   "core" = stable nodes only | "modal" = modal bootstrap membership | "empirical"
PLOT_HULL_MEMBERS    <- "core"
PLOT_LAYOUT_COASSIGN <- TRUE   # layout pull weighted by bootstrap co-assignment

# Community regions
PLOT_HULLS       <- TRUE
PLOT_HULL_TYPE   <- "hull"     # "hull" (needs concaveman) or "ellipse"
PLOT_HULL_ALPHA  <- 0.10
PLOT_HULL_EXPAND <- 12         # mm

# Layout
PLOT_LAYOUT     <- "fr_grouped" # fr_grouped / fr / kk / stress / circle
PLOT_GROUP_PULL <- 4            # within-community edge multiplier (layout only)
PLOT_SEED       <- 7

# Labels
PLOT_LABEL_MODE   <- "smart"    # "smart" (collision-aware) | "radial"
PLOT_LABEL_POS    <- c()        # manual: c(STBELSCIE = "w", GOALSET = "s") or degrees
PLOT_LABEL_NUDGE  <- list()     # fine-tune: list(STBELSCIE = c(-0.01, 0.005))
PLOT_LABEL_CHAR_W <- 0.55       # avg glyph width / font size (calibrate if boxes off)
PLOT_LABEL_SIZE   <- 3.3
PLOT_LABEL_GAP    <- 0.014
PLOT_CAPTION_WIDTH <- 170       # characters per caption line

# Edges: ONE common width scale proportional to |weight|
# Backbone: "topn" | "threshold" | "significant" | "stable" | "sig_stable"
PLOT_BACKBONE_RULE <- "threshold"
PLOT_BACKBONE_TOPN <- 12
PLOT_BACKBONE_MIN  <- 0.10
PLOT_STABLE_MIN    <- 0.80
PLOT_HIGHLIGHT_PV_EDGES <- TRUE
PLOT_EDGE_WIDTH_RANGE   <- c(0.25, 3.2)
PLOT_EDGE_POS_COLOUR    <- "#2F6DB5"
PLOT_EDGE_NEG_COLOUR    <- "#C0392B"
PLOT_BG_EDGE_COLOUR     <- "grey62"
PLOT_BG_EDGE_ALPHA      <- 0.35
PLOT_BB_EDGE_ALPHA      <- 0.85
PLOT_EDGE_CURVATURE     <- 0
PLOT_EDGE_LABELS        <- FALSE

# Palette for dimensions (used in ALL figures)
PLOT_PALETTE <- c("#1B9E77", "#7570B3", "#D95F02", "#E7298A",
                  "#66A61E", "#A6761D", "#666666", "#1F78B4")
PLOT_WIDTH  <- 12
PLOT_HEIGHT <- 9

NODE_LABELS <- c(
  CURIO     = "Curiosity",
  BELONG    = "Sense of\nbelonging",
  TEACHSUP  = "Teacher\nsupport",
  COGACSC   = "Cognitive\nactivation (sci.)",
  SCIECOLLR = "Collaborative\nscience reasoning",
  JOYSCIE   = "Enjoyment\nof science",
  EFFSCIE   = "Science\nself-efficacy",
  STBELSCIE = "Beliefs about\nscience",
  PERSEV    = "Perseverance",
  ENPROBS   = "Enjoyment of\nproblem-solving",
  COGABIL   = "Cognitive\nadaptability",
  GOALSET   = "Goal setting",
  SELFREG   = "Self-regulation",
  ENGSCIPR  = "Engagement with\nscience practices",
  GROWTHMND = "Growth\nmindset",
  VALSCHL   = "Value of\nschool",
  PV_SCIE   = "Science\nachievement"
)

# !! Community numbers can change when ADJUST_FOR / algorithm / seed change.
DIMENSION_LABELS <- c(
  "1" = "1 - Drive to Learn",
  "2" = "2 - School-Situated Regulatory Resources",
  "3" = "3 - Learning Opportunity Design",
  "4" = "4 - Science Dispositions and Competencies"
)

# ============================================================
# ======================  CONSTANTS  =========================
# ============================================================
M_PV <- 10L
PISA_MISSING_NUM <- c(95:99, 995:999, 9995:9999, 99995:99999)
Z_CRIT <- stats::qnorm(1 - (1 - CI_LEVEL) / 2)
`%||%` <- function(a, b) if (is.null(a)) b else a

# ============================================================
# ==================  METADATA HELPERS  ======================
# ============================================================

normalize_cntry_lookup <- function(lk) {
  canonical <- c(FCNT = "FCNT", CNT = "CNT", CNTRYID = "CNTRYID", COUNTRY = "Country")
  up <- toupper(names(lk)); hit <- up %in% names(canonical)
  names(lk)[hit] <- canonical[up[hit]]
  if (!("FCNT" %in% names(lk))) {
    if ("CNTRYID" %in% names(lk)) lk$FCNT <- lk$CNTRYID
    else stop("Lookup has neither FCNT nor CNTRYID.")
  }
  if (!("Country" %in% names(lk))) stop("Lookup has no Country column.")
  lk
}

parse_value_labels <- function(vl_string) {
  if (is.null(vl_string) || is.na(vl_string) || nchar(trimws(vl_string)) == 0) return(NULL)
  pairs <- trimws(strsplit(vl_string, ";")[[1]]); pairs <- pairs[nchar(pairs) > 0]
  codes <- labels <- character(length(pairs))
  for (i in seq_along(pairs)) {
    parts <- strsplit(pairs[i], "=", fixed = TRUE)[[1]]
    codes[i]  <- trimws(parts[1])
    labels[i] <- if (length(parts) >= 2) trimws(paste(parts[-1], collapse = "=")) else codes[i]
  }
  setNames(labels, codes)
}

build_variables_from_rds <- function(dat) {
  fmt_vl <- function(x) {
    l <- attr(x, "labels", exact = TRUE)
    if (is.null(l) || !length(l)) return(NA_character_)
    paste(paste(format(unname(l), scientific = FALSE, trim = TRUE), names(l), sep = " = "),
          collapse = "; ")
  }
  fmt_ms <- function(x) {
    nav <- attr(x, "na_values", exact = TRUE); nar <- attr(x, "na_range", exact = TRUE)
    parts <- character(0)
    if (length(nav)) parts <- c(parts, paste(format(nav, scientific = FALSE, trim = TRUE), collapse = ", "))
    if (length(nar) == 2 && all(is.finite(nar)))
      parts <- c(parts, paste0(nar[1], "~", nar[2]))
    if (!length(parts)) NA_character_ else paste(parts, collapse = "; ")
  }
  fmt_lab <- function(x) { l <- attr(x, "label", exact = TRUE); if (is.null(l)) NA_character_ else as.character(l)[1] }
  data.frame(Name = names(dat),
             Label = vapply(dat, fmt_lab, character(1)),
             `Value Labels` = vapply(dat, fmt_vl, character(1)),
             `Missing Values` = vapply(dat, fmt_ms, character(1)),
             stringsAsFactors = FALSE, check.names = FALSE)
}

pisa_classify_codes <- function(value_labels_str = "", missing_str = "") {
  out <- list(design_missing = character(0), invalid = character(0),
              no_response = character(0), not_reached = character(0), technical = character(0))
  vl <- parse_value_labels(value_labels_str)
  if (!is.null(vl)) for (cd in names(vl)) {
    lbl <- tolower(vl[[cd]])
    if (grepl("not\\s*applicable|not\\s*administered|valid\\s*skip|system\\s*missing|disengaged|embedded|timeout", lbl))
      out$design_missing <- c(out$design_missing, cd)
    else if (grepl("invalid|multiple\\s*response", lbl)) out$invalid <- c(out$invalid, cd)
    else if (grepl("no\\s*response|omitted", lbl))      out$no_response <- c(out$no_response, cd)
    else if (grepl("not\\s*reached", lbl))               out$not_reached <- c(out$not_reached, cd)
    else if (grepl("technical", lbl))                    out$technical <- c(out$technical, cd)
  }
  ms <- if (!is.null(missing_str) && !is.na(missing_str)) trimws(missing_str) else ""
  if (nchar(ms) > 0 && toupper(ms) != "NA") {
    tokens <- trimws(unlist(strsplit(ms, "[,;[:space:]]+"))); tokens <- tokens[nchar(tokens) > 0]
    expanded <- character(0)
    for (tok in tokens) {
      if (grepl("~", tok, fixed = TRUE)) {
        pr <- suppressWarnings(as.numeric(strsplit(tok, "~", fixed = TRUE)[[1]]))
        if (length(pr) == 2 && all(!is.na(pr)) && pr[1] <= pr[2] && diff(pr) <= 1e5)
          expanded <- c(expanded, as.character(seq.int(pr[1], pr[2])))
      } else expanded <- c(expanded, tok)
    }
    for (cd in unique(expanded)) {
      num <- suppressWarnings(as.numeric(cd)); if (is.na(num)) next
      last <- substr(cd, nchar(cd), nchar(cd))
      if (last == "8") out$invalid <- c(out$invalid, cd)
      else if (last == "9") out$no_response <- c(out$no_response, cd)
      else out$design_missing <- c(out$design_missing, cd)
    }
  }
  lapply(out, unique)
}

get_drop_codes <- function(vname, meta) {
  if (is.null(meta$vm) || is.na(meta$name)) return(numeric(0))
  idx <- which(meta$vm[[meta$name]] == vname)
  if (!length(idx)) return(numeric(0))
  vl <- if (!is.na(meta$vallabel)) meta$vm[[meta$vallabel]][idx[1]] else ""
  ms <- if (!is.na(meta$missing))  meta$vm[[meta$missing]][idx[1]]  else ""
  cls <- pisa_classify_codes(ifelse(is.na(vl), "", vl), ifelse(is.na(ms), "", ms))
  x <- suppressWarnings(as.numeric(unlist(cls, use.names = FALSE)))
  unique(x[!is.na(x)])
}

clean_numeric <- function(x_raw, vname, meta, type = c("wle", "item", "raw"),
                          max_scale = NULL, wle_abs_max = WLE_ABS_MAX) {
  type <- match.arg(type)
  x <- suppressWarnings(as.numeric(as.vector(x_raw)))
  codes <- get_drop_codes(vname, meta)
  if (type == "wle") codes <- codes[codes >= 95]
  if (length(codes)) x[x %in% codes] <- NA_real_
  bad <- rep(FALSE, length(x))
  if (type == "wle")
    bad <- !is.na(x) & (x %in% PISA_MISSING_NUM | abs(x) > wle_abs_max)
  if (type == "item")
    bad <- !is.na(x) & (x < 1 | x > max_scale | x != round(x))
  x[bad] <- NA_real_
  attr(x, "n_hard_removed") <- sum(bad)
  x
}

compute_item_composite <- function(df, items, reversed, max_scale, min_items, meta, w) {
  mat <- vapply(seq_along(items), function(j) {
    v <- clean_numeric(df[[items[j]]], items[j], meta, "item", max_scale)
    if (isTRUE(reversed[j])) v <- max_scale + 1 - v
    as.numeric(v)
  }, numeric(nrow(df)))
  mat <- matrix(mat, nrow = nrow(df))
  n_ok <- rowSums(!is.na(mat))
  score <- rowMeans(mat, na.rm = TRUE)
  score[n_ok < min_items | is.nan(score)] <- NA_real_
  alpha <- NA_real_
  if (ncol(mat) >= 2) {
    ok <- stats::complete.cases(mat) & !is.na(w) & w > 0
    if (sum(ok) > 10) {
      C <- stats::cov.wt(mat[ok, , drop = FALSE], wt = w[ok] / sum(w[ok]))$cov
      k <- ncol(mat); alpha <- k / (k - 1) * (1 - sum(diag(C)) / sum(C))
    }
  }
  list(score = score, alpha = alpha)
}

compute_construct <- function(df, items_info, meta, w, min_prop = 0.5) {
  items <- items_info$Item[items_info$Item %in% names(df)]
  if (!length(items)) return(list(score = rep(NA_real_, nrow(df)), alpha = NA_real_))
  ii <- items_info[match(items, items_info$Item), ]
  mx <- suppressWarnings(as.numeric(ii$Max_Scale_Value))
  mx[is.na(mx)] <- max(mx, 4, na.rm = TRUE)
  compute_item_composite(df, items, as.logical(ii$Reversed), max(mx),
                         max(1, ceiling(min_prop * length(items))), meta, w)
}

# ============================================================
# ===============  NETWORK / DESIGN HELPERS  =================
# ============================================================

call_safely <- function(fun, args, dots = list()) {
  fn <- names(formals(fun))
  args <- args[names(args) %in% fn]
  if ("..." %in% fn && length(dots)) args <- c(args, dots)
  do.call(fun, args)
}

wcor <- function(X, w) {
  w <- w / sum(w)
  mu <- colSums(X * w)
  Xc <- sweep(X, 2, mu, "-") * sqrt(w)
  V  <- crossprod(Xc); s <- sqrt(diag(V))
  R  <- V / tcrossprod(s); diag(R) <- 1
  R
}

cond_cor <- function(X, w, idx_n, idx_c) {
  C <- wcor(X, w)
  if (!length(idx_c)) return(C[idx_n, idx_n, drop = FALSE])
  S <- C[idx_n, idx_n, drop = FALSE] -
    C[idx_n, idx_c, drop = FALSE] %*% solve(C[idx_c, idx_c, drop = FALSE],
                                            C[idx_c, idx_n, drop = FALSE])
  R <- stats::cov2cor(S); R <- (R + t(R)) / 2; diag(R) <- 1
  R
}

pcor_from_R <- function(R) { P <- -stats::cov2cor(solve(R)); diag(P) <- 1; P }
fz <- function(r) atanh(pmin(pmax(r, -0.99999), 0.99999))

vec_to_sym <- function(v, p, nm, diag_val = 1) {
  M0 <- matrix(0, p, p); M0[upper.tri(M0)] <- v
  M0 <- M0 + t(M0); diag(M0) <- diag_val
  dimnames(M0) <- list(nm, nm); M0
}

pool_brr_rubin <- function(Z, fay_k = 0.5) {
  M <- dim(Z)[1]; G <- dim(Z)[2] - 1L; K <- dim(Z)[3]
  full <- matrix(Z[, 1, ], nrow = M, ncol = K)
  U <- matrix(NA_real_, M, K)
  for (m in seq_len(M)) {
    rep_m <- matrix(Z[m, -1, ], nrow = G, ncol = K)
    U[m, ] <- colSums(sweep(rep_m, 2, full[m, ], "-")^2) / (G * (1 - fay_k)^2)
  }
  qbar <- colMeans(full); Ubar <- colMeans(U)
  B  <- if (M > 1) apply(full, 2, stats::var) else rep(0, K)
  Tv <- Ubar + (1 + 1 / M) * B
  list(qbar = qbar, Ubar = Ubar, B = B, T = Tv,
       fmi = ifelse(Tv > 0, (1 + 1 / M) * B / Tv, 0))
}

repair_pd_correlation <- function(R, eps = 1e-4) {
  R <- (R + t(R)) / 2; diag(R) <- 1
  if (requireNamespace("Matrix", quietly = TRUE)) {
    np <- tryCatch(Matrix::nearPD(R, corr = TRUE, keepDiag = TRUE, posd.tol = eps),
                   error = function(e) NULL)
    if (!is.null(np)) { out <- as.matrix(np$mat); dimnames(out) <- dimnames(R); return(out) }
  }
  ev <- eigen(R, symmetric = TRUE)
  out <- ev$vectors %*% diag(pmax(ev$values, eps)) %*% t(ev$vectors)
  out <- stats::cov2cor(out); dimnames(out) <- dimnames(R); out
}

run_ega <- function(R, n, model, algorithm, uni.method, seed = NULL) {
  dots <- if (identical(algorithm, "leiden")) LEIDEN_ARGS else list()
  if (!is.null(seed)) set.seed(seed)
  call_safely(EGAnet::EGA,
              list(data = R, n = n, model = model, algorithm = algorithm,
                   uni.method = uni.method, plot.EGA = FALSE, verbose = FALSE),
              dots)
}

get_wc <- function(e, nodes) {
  wc <- e$wc
  if (is.null(wc)) return(rep(NA_integer_, length(nodes)))
  if (!is.null(names(wc)) && all(nodes %in% names(wc))) wc <- wc[nodes]
  as.integer(wc)
}

ari_safe <- function(a, b) {
  fill <- function(x) { x <- as.integer(x); i <- which(is.na(x))
  if (length(i)) x[i] <- max(c(0L, x), na.rm = TRUE) + seq_along(i); x }
  tryCatch(igraph::compare(fill(a), fill(b), method = "adjusted.rand"),
           error = function(e) NA_real_)
}

# TEFI (EGAnet 2.x: no 'n'; lower = better)
tefi_safe <- function(R, wc) {
  tryCatch({
    t0 <- call_safely(EGAnet::tefi, list(data = R, structure = as.integer(wc), verbose = FALSE))
    if (is.data.frame(t0) && "VN.Entropy.Fit" %in% names(t0)) t0$VN.Entropy.Fit[1]
    else as.numeric(unlist(t0))[1]
  }, error = function(e) NA_real_)
}

align_memberships <- function(boot_wc, emp_wc) {
  boot_wc <- as.integer(boot_wc); emp_wc <- as.integer(emp_wc)
  emp_labs <- sort(unique(emp_wc[!is.na(emp_wc)]))
  boot_labs <- sort(unique(boot_wc[!is.na(boot_wc)]))
  if (!length(boot_labs)) return(rep(NA_integer_, length(boot_wc)))
  C <- outer(emp_labs, boot_labs,
             Vectorize(function(a, b) sum(emp_wc == a & boot_wc == b, na.rm = TRUE)))
  C <- matrix(C, nrow = length(emp_labs))
  mapping <- setNames(rep(NA_integer_, length(boot_labs)), boot_labs)
  done <- FALSE
  if (requireNamespace("clue", quietly = TRUE) && length(emp_labs)) {
    nmax <- max(dim(C)); Cp <- matrix(0, nmax, nmax); Cp[seq_len(nrow(C)), seq_len(ncol(C))] <- C
    asg <- tryCatch(clue::solve_LSAP(Cp, maximum = TRUE), error = function(e) NULL)
    if (!is.null(asg)) {
      for (ii in seq_along(emp_labs)) {
        jj <- as.integer(asg[ii])
        if (jj <= length(boot_labs) && C[ii, jj] > 0) mapping[jj] <- emp_labs[ii]
      }
      done <- TRUE
    }
  }
  if (!done && length(emp_labs)) {
    Ct <- C
    repeat {
      if (max(Ct) <= 0) break
      pos <- which(Ct == max(Ct), arr.ind = TRUE)[1, ]
      mapping[pos[2]] <- emp_labs[pos[1]]; Ct[pos[1], ] <- -Inf; Ct[, pos[2]] <- -Inf
    }
  }
  nextlab <- max(c(emp_labs, 0L)) + 1L
  for (k in seq_along(mapping)) if (is.na(mapping[k])) { mapping[k] <- nextlab; nextlab <- nextlab + 1L }
  out <- rep(NA_integer_, length(boot_wc)); hit <- !is.na(boot_wc)
  out[hit] <- as.integer(mapping[as.character(boot_wc[hit])]); out
}

# Structural consistency = EXACT recovery of the item set.
# Core consistency = exact recovery of the STABLE items only (bridge nodes ignored).
build_stability_tables <- function(assign_mat, emp_vec, node_names, stab_threshold = 0.70) {
  emp_vec <- as.integer(emp_vec); B <- nrow(assign_mat)
  emp_mat <- matrix(emp_vec, nrow = B, ncol = length(emp_vec), byrow = TRUE)
  item_stab <- colMeans(assign_mat == emp_mat, na.rm = TRUE)
  item_stab[is.nan(item_stab) | is.na(emp_vec)] <- NA_real_
  item_df <- tibble(Node = node_names, Community = emp_vec, Item_Stability = item_stab)
  core <- !is.na(item_stab) & item_stab >= stab_threshold
  dims <- sort(unique(emp_vec[!is.na(emp_vec)]))
  dim_df <- map_dfr(dims, function(d) {
    idx <- which(emp_vec == d)
    rec <- apply(assign_mat, 1, function(r)
      all(!is.na(r[idx]) & r[idx] == d) && sum(r == d, na.rm = TRUE) == length(idx))
    idc <- which(emp_vec == d & core)
    rec_core <- if (length(idc)) apply(assign_mat, 1, function(r)
      all(!is.na(r[idc]) & r[idc] == d) && sum(r[core] == d, na.rm = TRUE) == length(idc)) else NA
    tibble(Dimension = d, N_items = length(idx),
           Structural_Consistency = mean(rec),
           N_core = length(idc), Core_Consistency = mean(rec_core),
           Avg_Item_Stability = mean(item_stab[idx], na.rm = TRUE))
  })
  list(item = item_df, dim = dim_df)
}

summarise_stability <- function(wc_raw, emp_wc, node_names, source_lab,
                                stab_threshold = ITEM_STAB_THRESHOLD) {
  wc_raw <- as.matrix(wc_raw)
  wc_raw <- wc_raw[rowSums(!is.na(wc_raw)) > 0, , drop = FALSE]
  if (nrow(wc_raw) < 10) return(NULL)
  aligned <- t(apply(wc_raw, 1, align_memberships, emp_wc = emp_wc))
  colnames(aligned) <- node_names
  tabs <- build_stability_tables(aligned, emp_wc, node_names, stab_threshold)
  
  # Membership proportions per node (aligned to empirical labels)
  K_emp <- sort(unique(as.integer(emp_wc[!is.na(emp_wc)])))
  memb <- t(vapply(seq_along(node_names), function(j) {
    a <- aligned[, j]; a <- a[!is.na(a)]
    if (!length(a)) return(rep(0, length(K_emp) + 1))
    c(vapply(K_emp, function(k) mean(a == k), numeric(1)), mean(!(a %in% K_emp)))
  }, numeric(length(K_emp) + 1)))
  dimnames(memb) <- list(node_names, c(as.character(K_emp), "Other"))
  
  # Modal community + RUNNER-UP (best community after the modal one)
  modal_j <- max.col(memb, ties.method = "first")
  modal_k <- colnames(memb)[modal_j]
  modal_p <- memb[cbind(seq_len(nrow(memb)), modal_j)]
  memb_alt <- memb
  memb_alt[cbind(seq_len(nrow(memb)), modal_j)] <- -1
  alt_j <- max.col(memb_alt, ties.method = "first")
  alt_k <- colnames(memb)[alt_j]
  alt_p <- pmax(memb_alt[cbind(seq_len(nrow(memb)), alt_j)], 0)
  alt_k[alt_p <= 0] <- NA_character_
  
  tabs$item <- tabs$item |>
    mutate(Modal_Community = modal_k, Modal_Prop = unname(modal_p),
           Alt_Community = alt_k, Alt_Prop = unname(alt_p),
           Modal_differs = !is.na(Community) & Modal_Community != as.character(Community),
           Bridge = !is.na(Item_Stability) & Item_Stability < stab_threshold)
  
  ndim <- apply(wc_raw, 1, function(r) length(unique(r[!is.na(r)])))
  ari  <- apply(wc_raw, 1, ari_safe, b = emp_wc)
  p <- length(node_names)
  co <- matrix(NA_real_, p, p, dimnames = list(node_names, node_names))
  for (i in seq_len(p)) for (j in seq_len(p))
    co[i, j] <- mean(wc_raw[, i] == wc_raw[, j], na.rm = TRUE)
  list(item = tabs$item, dim = tabs$dim, ndim = ndim, ari = ari, coassign = co,
       memb_prop = memb, n_used = nrow(wc_raw), source = source_lab)
}

# ============================================================
# ====================  PLOT HELPERS  ========================
# ============================================================

flat_label <- function(x) {
  lab <- ifelse(x %in% names(NODE_LABELS), NODE_LABELS[x], x)
  unname(gsub("\n", " ", lab))
}
dim_name <- function(x) {
  out <- ifelse(is.na(x), "Unassigned", as.character(x))
  if (!is.null(DIMENSION_LABELS)) {
    hit <- out %in% names(DIMENSION_LABELS); out[hit] <- DIMENSION_LABELS[out[hit]]
  }
  unname(out)
}
dim_short <- function(k) ifelse(is.na(k), "none", ifelse(k == "Other", "other", paste("Dim", k)))

# Consistent dimension colours across ALL figures
dim_fill_values <- function(ids) {
  ids <- sort(unique(suppressWarnings(as.integer(ids[!is.na(ids)]))))
  c(setNames(rep_len(PLOT_PALETTE, length(ids)), dim_name(ids)), Unassigned = "grey75")
}
wrap_caption <- function(parts, width = PLOT_CAPTION_WIDTH)
  paste(vapply(parts, function(s) paste(strwrap(s, width), collapse = "\n"), character(1)),
        collapse = "\n")

# Fully build + lay out a ggplot off-screen (ggplot errors are lazy: they only
# surface at render time). Returns TRUE or throws the real error.
check_renderable <- function(p) {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  suppressWarnings(suppressMessages(ggplot2::ggplotGrob(p)))
  TRUE
}

save_plot <- function(p, stub, width, height) {
  if (is.null(p)) return(invisible(FALSE))
  ok <- tryCatch(check_renderable(p), error = function(e) {
    message("Plot '", stub, "' cannot be rendered (not saved): ", conditionMessage(e)); FALSE })
  if (!isTRUE(ok)) return(invisible(FALSE))
  for (fmt in PLOT_FORMATS) {
    f <- file.path(OUTPUT_DIR, paste0(stub, "_", stamp, ".", fmt))
    res <- tryCatch({
      if (fmt == "pdf") {
        dev <- if (capabilities("cairo")) grDevices::cairo_pdf else "pdf"
        ggsave(f, p, device = dev, width = width, height = height, units = "in", bg = "white")
      } else if (fmt == "tiff") {
        ggsave(f, p, device = "tiff", width = width, height = height, units = "in",
               dpi = PLOT_DPI, compression = "lzw", bg = "white")
      } else {
        ggsave(f, p, device = fmt, width = width, height = height, units = "in",
               dpi = PLOT_DPI, bg = "white")
      }
      TRUE
    }, error = function(e) { message("Save failed (", f, "): ", conditionMessage(e)); FALSE })
    if (!isTRUE(res) && file.exists(f)) unlink(f)      # never leave blank files
  }
  invisible(TRUE)
}

theme_pub <- function(base = 12) {
  theme_minimal(base_size = base) +
    theme(panel.grid.minor = element_blank(),
          plot.title = element_text(face = "bold"),
          plot.title.position = "plot",
          legend.title = element_text(face = "bold"))
}

plot_item_stability <- function(item_df, threshold, title_txt) {
  d <- item_df |> filter(!is.na(Item_Stability)) |>
    mutate(Label = flat_label(Node), Dimension = dim_name(Community)) |>
    arrange(Community, Item_Stability) |>
    mutate(Label = factor(Label, levels = unique(Label)))
  p <- ggplot(d, aes(Item_Stability, Label, colour = Dimension)) +
    geom_segment(aes(x = 0, xend = Item_Stability, yend = Label), linewidth = 0.6, alpha = 0.5) +
    geom_point(size = 3) +
    geom_vline(xintercept = threshold, linetype = "dashed", colour = "grey40") +
    scale_colour_manual(values = dim_fill_values(item_df$Community)) +
    scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
    labs(title = if (PLOT_SHOW_TITLE) title_txt, x = "Item stability (proportion of replicates)",
         y = NULL, colour = "Dimension") +
    theme_pub()
  if (all(c("Modal_Community", "Alt_Community", "Modal_differs") %in% names(d))) {
    da <- d |> filter(Item_Stability < threshold) |>
      mutate(txt = ifelse(Modal_differs,
                          sprintf("modal: %s (%.0f%%)", dim_short(Modal_Community), 100 * Modal_Prop),
                          sprintf("alt.: %s (%.0f%%)", dim_short(Alt_Community), 100 * Alt_Prop)))
    if (nrow(da)) p <- p + geom_text(data = da, aes(x = Item_Stability, label = txt),
                                     hjust = 0, nudge_x = 0.03, size = 3.2,
                                     colour = "grey25", show.legend = FALSE)
  }
  p
}

plot_dimension_stability <- function(dim_df, title_txt) {
  d <- dim_df |> mutate(Dim_lab = dim_name(Dimension)) |>
    mutate(Dim_lab = factor(Dim_lab, levels = Dim_lab[order(Structural_Consistency)]))
  ggplot(d, aes(y = Dim_lab)) +
    geom_col(aes(x = Structural_Consistency, fill = Dim_lab), width = 0.7, alpha = 0.9) +
    geom_point(aes(x = Core_Consistency, shape = "Core items only (bridge nodes ignored)"),
               size = 3.4, fill = "white", colour = "grey15", stroke = 0.9, na.rm = TRUE) +
    geom_vline(xintercept = 0.70, linetype = "dashed", colour = "grey40") +
    scale_fill_manual(values = dim_fill_values(dim_df$Dimension), guide = "none") +
    scale_shape_manual(values = 23, name = NULL) +
    scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
    labs(title = if (PLOT_SHOW_TITLE) title_txt,
         x = "Structural consistency (bar = all items; \u25C6 = core items only)", y = NULL) +
    theme_pub() + theme(legend.position = "bottom")
}

plot_ndim <- function(ndim, emp_ndim, title_txt) {
  d <- tibble(n_dim = ndim) |> count(n_dim) |> mutate(prop = n / sum(n),
                                                      empirical = n_dim == emp_ndim)
  ggplot(d, aes(factor(n_dim), prop, fill = empirical)) +
    geom_col(width = 0.7) +
    geom_text(aes(label = scales::percent(prop, accuracy = 0.1)), vjust = -0.4, size = 3.5) +
    scale_fill_manual(values = c(`TRUE` = "#3C5488", `FALSE` = "grey70"), guide = "none") +
    scale_y_continuous(labels = scales::percent, expand = expansion(mult = c(0, 0.1))) +
    labs(title = if (PLOT_SHOW_TITLE) title_txt, x = "Number of dimensions", y = "Replicates") +
    theme_pub()
}

plot_coassign <- function(co, wc, title_txt) {
  ord <- names(sort(wc, na.last = TRUE))
  d <- as_tibble(as.data.frame(as.table(co))) |>
    setNames(c("A", "B", "Prop")) |>
    mutate(A = factor(flat_label(as.character(A)), levels = flat_label(ord)),
           B = factor(flat_label(as.character(B)), levels = rev(flat_label(ord))))
  ggplot(d, aes(A, B, fill = Prop)) +
    geom_tile(colour = "white") +
    geom_text(aes(label = sprintf("%.2f", Prop)), size = 2.4) +
    scale_fill_gradient(low = "white", high = "#3C5488", limits = c(0, 1), name = "Co-assignment") +
    labs(title = if (PLOT_SHOW_TITLE) title_txt, x = NULL, y = NULL) +
    theme_pub(10) + theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

plot_pv_forest <- function(edge_tab, pv_nodes, title_txt) {
  d <- edge_tab |>
    filter(From %in% pv_nodes | To %in% pv_nodes) |>
    mutate(PV = ifelse(From %in% pv_nodes, From, To),
           Partner = ifelse(From %in% pv_nodes, To, From),
           Partner_lab = flat_label(Partner),
           Significant = ifelse(pcor_q < FDR_ALPHA, paste0("FDR q < ", FDR_ALPHA), "n.s.")) |>
    mutate(Partner_lab = reorder(Partner_lab, pcor))
  ggplot(d, aes(y = Partner_lab)) +
    geom_vline(xintercept = 0, colour = "grey50") +
    geom_linerange(aes(xmin = pcor_lo, xmax = pcor_hi), linewidth = 0.8, colour = "grey30") +
    geom_point(aes(x = pcor, fill = Significant), shape = 21, size = 3) +
    geom_point(aes(x = glasso_weight), shape = 4, size = 2.5, colour = "#E64B35") +
    scale_fill_manual(values = setNames(c("#3C5488", "white"),
                                        c(paste0("FDR q < ", FDR_ALPHA), "n.s.")), name = NULL) +
    facet_wrap(~ PV) +
    labs(title = if (PLOT_SHOW_TITLE) title_txt,
         x = sprintf("Partial correlation with achievement (%d%% CI, BRR x Rubin)", round(100 * CI_LEVEL)),
         y = NULL,
         caption = "Circles: unregularised design-based partial correlation; red x: EGA (EBICglasso) edge weight") +
    theme_pub()
}

# ---- Label placement helpers -------------------------------
label_box_size <- function(labels, special, mm_per_unit) {
  ln  <- strsplit(labels, "\n", fixed = TRUE)
  nch <- vapply(ln, function(z) max(nchar(z)), numeric(1))
  nl  <- lengths(ln)
  fs  <- PLOT_LABEL_SIZE * ifelse(special, 1.06, 1)       # font size in mm
  list(w = (nch * PLOT_LABEL_CHAR_W * fs + 1.5) / mm_per_unit,
       h = (nl * fs * 1.2 * 0.88 + 1.0) / mm_per_unit)
}

compass_to_rad <- function(v) {
  map <- c(e = 0, ne = 45, n = 90, nw = 135, w = 180, sw = 225, s = 270, se = 315)
  v <- tolower(as.character(v))
  deg <- if (v %in% names(map)) map[[v]] else suppressWarnings(as.numeric(v))
  deg * pi / 180
}

# Greedy collision-aware placement: 24 directions x 2 distances per node.
# Score = node overlap + label overlap + edge crossings + outward preference.
place_labels_smart <- function(nd, seg, mm_per_unit, r_eff, base, sz, n_angles = 24) {
  n <- nrow(nd)
  out_ang <- atan2(nd$y - mean(nd$y), nd$x - mean(nd$x))
  angs <- seq(0, 2 * pi, length.out = n_angles + 1)[seq_len(n_angles)]
  far  <- c(0, 0.035)
  has_seg <- nrow(seg) > 0
  if (has_seg) {
    tt <- seq(0.04, 0.96, length.out = 30)
    px <- outer(seg$x, 1 - tt) + outer(seg$xend, tt)
    py <- outer(seg$y, 1 - tt) + outer(seg$yend, tt)
    ew <- ifelse(seg$bb, 3, 1)
  }
  pad <- 1.0 / mm_per_unit
  box_at <- function(i, a, k) {
    fx <- sign(cos(a)) * pmin(1, abs(cos(a)) * 2)
    fy <- sign(sin(a)) * pmin(1, abs(sin(a)) * 2)
    c(nd$x[i] + cos(a) * (base[i] + k) + fx * sz$w[i] / 2,
      nd$y[i] + sin(a) * (base[i] + k) + fy * sz$h[i] / 2)
  }
  manual <- intersect(names(PLOT_LABEL_POS), nd$name)
  crowd <- vapply(seq_len(n), function(i)
    sum(sqrt((nd$x - nd$x[i])^2 + (nd$y - nd$y[i])^2) < 0.25) - 1, numeric(1))
  man_idx <- match(manual, nd$name)
  ord <- c(man_idx, setdiff(order(-crowd), man_idx))
  placed <- matrix(numeric(0), 0, 4)
  lx <- ly <- rep(NA_real_, n)
  for (i in ord) {
    w <- sz$w[i]; h <- sz$h[i]
    cand_a <- angs
    if (nd$name[i] %in% manual) {
      a0 <- compass_to_rad(PLOT_LABEL_POS[[nd$name[i]]]); if (!is.na(a0)) cand_a <- a0
    }
    grid <- expand.grid(a = cand_a, k = far)
    sc <- vapply(seq_len(nrow(grid)), function(g) {
      a <- grid$a[g]; k <- grid$k[g]
      b <- box_at(i, a, k)
      x0 <- b[1] - w / 2; x1 <- b[1] + w / 2; y0 <- b[2] - h / 2; y1 <- b[2] + h / 2
      dx <- pmax(x0 - nd$x, 0, nd$x - x1); dy <- pmax(y0 - nd$y, 0, nd$y - y1)
      pen_node <- sum(pmax(0, r_eff + pad - sqrt(dx^2 + dy^2)) / pad)
      pen_lab <- if (nrow(placed))
        sum(pmax(0, pmin(x1, placed[, 2]) - pmax(x0, placed[, 1])) *
              pmax(0, pmin(y1, placed[, 4]) - pmax(y0, placed[, 3]))) / (w * h) else 0
      pen_edge <- if (has_seg)
        sum(rowMeans(px >= x0 & px <= x1 & py >= y0 & py <= y1) * ew) else 0
      pen_dir <- 1 - cos(a - out_ang[i])
      50 * pen_node + 40 * pen_lab + 2 * pen_edge + 0.8 * pen_dir + ifelse(k > 0, 1.5, 0)
    }, numeric(1))
    best <- which.min(sc)
    b <- box_at(i, grid$a[best], grid$k[best])
    lx[i] <- b[1]; ly[i] <- b[2]
    placed <- rbind(placed, c(b[1] - w / 2, b[1] + w / 2, b[2] - h / 2, b[2] + h / 2))
  }
  list(x = unname(lx), y = unname(ly))
}

# ---- Main network figure -----------------------------------
plot_ega_network <- function(edges_in, node_names, comm_vec, backbone_flag,
                             pred = NULL, item_stab = NULL, strength = NULL,
                             memb_prop = NULL, coassign = NULL,
                             special_nodes = NULL, stab_threshold = 0.70,
                             title_txt = NULL, subtitle_txt = NULL, caption_txt = NULL) {
  need <- c("ggraph", "tidygraph", "ggrepel", "ggforce", "scales")
  miss <- need[!vapply(need, requireNamespace, logical(1), quietly = TRUE)]
  if (length(miss)) { message("Network plot needs: ", paste(miss, collapse = ", ")); return(NULL) }
  if (is.null(edges_in) || !nrow(edges_in)) return(NULL)
  pick <- function(v) if (is.null(v)) rep(NA_real_, length(node_names)) else unname(as.numeric(v[node_names]))
  
  # ---- Nodes ----
  cv <- as.integer(comm_vec[node_names])
  comm_chr <- ifelse(is.na(cv), "Unassigned", as.character(cv))
  lv <- c(as.character(sort(unique(cv[!is.na(cv)]))), if (anyNA(cv)) "Unassigned")
  lab_lv <- dim_name(lv)
  nd <- tibble(
    name      = node_names,
    community = factor(comm_chr, levels = lv, labels = lab_lv),
    label     = if (isTRUE(PLOT_FULL_LABELS))
      unname(ifelse(node_names %in% names(NODE_LABELS), NODE_LABELS[node_names], node_names)) else node_names,
    special   = node_names %in% special_nodes,
    pred = pick(pred), stab = pick(item_stab), strength = pick(strength))
  nd$unstable <- !is.na(nd$stab) & nd$stab < stab_threshold
  has_memb <- !is.null(memb_prop) && all(node_names %in% rownames(memb_prop))
  nd$pie  <- nd$unstable & PLOT_BRIDGE_STYLE %in% c("pie", "both") & has_memb
  nd$halo <- nd$unstable & PLOT_BRIDGE_STYLE %in% c("halo", "both")
  modal_chr <- comm_chr
  if (has_memb) {
    mp <- memb_prop[node_names, , drop = FALSE]
    mc <- colnames(mp)[max.col(mp, ties.method = "first")]
    modal_chr <- ifelse(mc == "Other", comm_chr, mc)
  }
  
  # ---- Edges (weak first -> strong drawn on top) ----
  weak_lab <- "Weaker edge"
  ed <- tibble(from = edges_in$From, to = edges_in$To, w_signed = edges_in$Weight,
               backbone = as.logical(backbone_flag) %in% TRUE) |>
    mutate(abs_w  = abs(w_signed),
           cls    = ifelse(backbone, ifelse(w_signed > 0, "Positive", "Negative"), weak_lab),
           ealpha = ifelse(backbone, PLOT_BB_EDGE_ALPHA, PLOT_BG_EDGE_ALPHA)) |>
    arrange(backbone, abs_w)
  
  # ---- Layout: pull weighted by community (or bootstrap co-assignment) ----
  ig <- igraph::graph_from_data_frame(ed, directed = FALSE, vertices = nd)
  w  <- igraph::E(ig)$abs_w
  en <- igraph::ends(ig, igraph::E(ig), names = TRUE)
  same <- comm_chr[match(en[, 1], node_names)] == comm_chr[match(en[, 2], node_names)]
  if (isTRUE(PLOT_LAYOUT_COASSIGN) && !is.null(coassign) && all(node_names %in% rownames(coassign))) {
    ca <- coassign[cbind(match(en[, 1], rownames(coassign)), match(en[, 2], colnames(coassign)))]
    ca[is.na(ca)] <- as.numeric(same[is.na(ca)])
  } else ca <- as.numeric(same)
  w_grp <- w * (1 + (PLOT_GROUP_PULL - 1) * ca)
  set.seed(PLOT_SEED)
  lay <- switch(PLOT_LAYOUT,
                fr_grouped = igraph::layout_with_fr(ig, weights = w_grp, niter = 2000),
                fr         = igraph::layout_with_fr(ig, weights = w, niter = 2000),
                kk         = igraph::layout_with_kk(ig, weights = 1 / (w_grp + 0.01)),
                stress     = if (requireNamespace("graphlayouts", quietly = TRUE))
                  graphlayouts::layout_with_stress(ig, weights = 1 / (w_grp + 0.01))
                else igraph::layout_with_fr(ig, weights = w_grp, niter = 2000),
                circle     = igraph::layout_in_circle(ig, order = order(comm_chr)),
                igraph::layout_with_fr(ig, weights = w_grp, niter = 2000))
  lay <- sweep(lay, 2, colMeans(lay))
  lay <- lay / max(apply(lay, 2, function(z) diff(range(z))), 1e-9)
  nd$x <- lay[, 1]; nd$y <- lay[, 2]
  igraph::V(ig)$x <- nd$x; igraph::V(ig)$y <- nd$y
  
  # ---- Node radius ----
  size_var <- switch(PLOT_NODE_SIZE_BY, item_stability = nd$stab,
                     predictability = nd$pred, strength = nd$strength, NULL)
  if (is.null(size_var) || all(is.na(size_var))) {
    nd$r <- PLOT_NODE_RADIUS
  } else {
    from <- if (PLOT_NODE_SIZE_BY == "strength") range(size_var, na.rm = TRUE) else c(0, 1)
    sv   <- ifelse(is.na(size_var), from[1], size_var)
    nd$r <- if (diff(from) > 1e-9)
      scales::rescale(sqrt(pmax(sv, 0)), to = PLOT_NODE_RADIUS_RANGE, from = sqrt(pmax(from, 0)))
    else mean(PLOT_NODE_RADIUS_RANGE)
  }
  
  # ---- Ring ----
  ring_val <- switch(PLOT_NODE_RING, predictability = nd$pred, item_stability = nd$stab, NULL)
  has_ring <- !is.null(ring_val) && any(!is.na(ring_val))
  nd$ring  <- if (has_ring) pmin(pmax(ring_val, 0), 1) else NA_real_
  rw       <- if (has_ring) PLOT_RING_WIDTH else 0
  nd$r_out <- nd$r + rw
  extra    <- ifelse(nd$halo, 0.012, ifelse(nd$special, 0.008, 0))
  r_eff    <- nd$r_out + extra
  
  # ---- Scale estimate (mm per data unit) for label boxes ----
  xr0 <- range(c(nd$x - r_eff, nd$x + r_eff)) + c(-0.22, 0.22)
  yr0 <- range(c(nd$y - r_eff, nd$y + r_eff)) + c(-0.10, 0.10)
  mm_per_unit <- min((PLOT_WIDTH - 3.2) * 25.4 / diff(xr0),
                     (PLOT_HEIGHT - 2.6) * 25.4 / (diff(yr0) + 0.15))
  sz <- label_box_size(nd$label, nd$special, mm_per_unit)
  
  # ---- Labels ----
  seg <- tibble(x = nd$x[match(ed$from, nd$name)], y = nd$y[match(ed$from, nd$name)],
                xend = nd$x[match(ed$to, nd$name)], yend = nd$y[match(ed$to, nd$name)],
                bb = ed$backbone)
  base <- r_eff + PLOT_LABEL_GAP
  if (identical(PLOT_LABEL_MODE, "smart")) {
    pl <- place_labels_smart(nd, seg, mm_per_unit, r_eff, base, sz)
    nd$lx <- pl$x; nd$ly <- pl$y; nd$hj <- 0.5; nd$vj <- 0.5
  } else {
    ang <- atan2(nd$y - mean(nd$y), nd$x - mean(nd$x))
    nd$lx <- nd$x + cos(ang) * base; nd$ly <- nd$y + sin(ang) * base
    nd$hj <- ifelse(cos(ang) > 0.35, 0, ifelse(cos(ang) < -0.35, 1, 0.5))
    nd$vj <- ifelse(sin(ang) > 0.35, 0, ifelse(sin(ang) < -0.35, 1, 0.5))
  }
  for (nm in intersect(names(PLOT_LABEL_NUDGE), nd$name)) {
    i <- match(nm, nd$name); nv <- as.numeric(PLOT_LABEL_NUDGE[[nm]])
    nd$lx[i] <- nd$lx[i] + nv[1]; nd$ly[i] <- nd$ly[i] + (if (length(nv) > 1) nv[2] else 0)
  }
  nd <- nd |> mutate(ff = ifelse(special, "bold.italic", "bold"),
                     lab_col = ifelse(special, "#7A5C00", "grey15"))
  
  xr <- range(c(nd$x - r_eff, nd$x + r_eff, nd$lx - sz$w, nd$lx + sz$w)) + c(-0.03, 0.03)
  yr <- range(c(nd$y - r_eff, nd$y + r_eff, nd$ly - sz$h, nd$ly + sz$h)) + c(-0.03, 0.03)
  key_y <- yr[1] - 0.06
  lab_df <- bind_rows(
    nd |> transmute(x = lx, y = ly, label, hj, vj, ff, lab_col, ps = 0),
    nd |> transmute(x, y, label = "", hj = 0.5, vj = 0.5, ff = "plain",
                    lab_col = "black", ps = 2 * r_eff * mm_per_unit))
  
  # ---- Scales ----
  fills_all <- c(dim_fill_values(cv), Other = "grey80")
  gold <- "#B8860B"
  edge_vals <- c(Positive = PLOT_EDGE_POS_COLOUR, Negative = PLOT_EDGE_NEG_COLOUR)
  edge_vals[weak_lab] <- PLOT_BG_EDGE_COLOUR
  wmax <- max(ed$abs_w)
  br <- c(0.05, 0.10, 0.20, 0.30, 0.40, 0.50); br <- br[br <= wmax]
  if (length(br) < 2) br <- scales::breaks_pretty(3)(c(0, wmax))
  
  # ---- Build plot ----
  p <- ggraph::ggraph(tidygraph::as_tbl_graph(ig), layout = "manual", x = x, y = y)
  
  if (isTRUE(PLOT_HULLS)) {
    hull_chr <- switch(PLOT_HULL_MEMBERS,
                       core  = ifelse(nd$unstable, NA_character_, comm_chr),
                       modal = modal_chr,
                       comm_chr)
    hd <- nd |> mutate(hull = factor(hull_chr, levels = lv, labels = lab_lv)) |> filter(!is.na(hull))
    use_hull <- PLOT_HULL_TYPE == "hull" && requireNamespace("concaveman", quietly = TRUE)
    mark <- if (use_hull) ggforce::geom_mark_hull else ggforce::geom_mark_ellipse
    p <- p + mark(data = hd, mapping = aes(x = x, y = y, group = hull, fill = hull),
                  inherit.aes = FALSE, alpha = PLOT_HULL_ALPHA, colour = NA,
                  expand = unit(PLOT_HULL_EXPAND, "mm"), radius = unit(PLOT_HULL_EXPAND, "mm"),
                  show.legend = FALSE)
  }
  
  p <- p +
    ggraph::geom_edge_arc(aes(edge_colour = cls, edge_width = abs_w, edge_alpha = ealpha),
                          strength = PLOT_EDGE_CURVATURE, lineend = "round") +
    ggraph::scale_edge_colour_manual(values = edge_vals,
                                     breaks = intersect(names(edge_vals), unique(ed$cls)),
                                     name = "Edge",
                                     guide = guide_legend(order = 2,
                                                          override.aes = list(edge_width = 1.5))) +
    ggraph::scale_edge_width_continuous(range = PLOT_EDGE_WIDTH_RANGE, limits = c(0, wmax),
                                        breaks = br, name = "|Edge weight|",
                                        guide = guide_legend(order = 3)) +
    ggraph::scale_edge_alpha_identity()
  
  if (isTRUE(PLOT_EDGE_LABELS))
    p <- p + ggraph::geom_edge_arc(aes(filter = backbone, label = sprintf("%.2f", w_signed)),
                                   strength = PLOT_EDGE_CURVATURE, edge_alpha = 0,
                                   label_size = 2.5, label_colour = "grey20",
                                   angle_calc = "along", label_dodge = unit(2, "mm"),
                                   show.legend = FALSE)
  
  if (has_ring) {
    rd <- filter(nd, !is.na(ring))
    p <- p +
      ggforce::geom_arc_bar(data = rd, aes(x0 = x, y0 = y, r0 = r, r = r_out, start = 0, end = 2 * pi),
                            inherit.aes = FALSE, fill = "grey88", colour = NA) +
      ggforce::geom_arc_bar(data = rd, aes(x0 = x, y0 = y, r0 = r, r = r_out, start = 0, end = 2 * pi * ring),
                            inherit.aes = FALSE, fill = "grey25", colour = NA)
  }
  
  # Stable nodes: solid fill
  p <- p + ggforce::geom_circle(data = filter(nd, !pie), aes(x0 = x, y0 = y, r = r, fill = community),
                                inherit.aes = FALSE, colour = "white", linewidth = 0.6)
  # Bridge nodes: split fill by bootstrap membership (fill MAPPED, not fixed)
  if (any(nd$pie)) {
    pie_df <- map_dfr(which(nd$pie), function(i) {
      v <- memb_prop[nd$name[i], ]; v <- v[v > 0.005]; v <- sort(v, decreasing = TRUE); v <- v / sum(v)
      ends <- cumsum(v) * 2 * pi; starts <- c(0, head(ends, -1))
      tibble(x0 = nd$x[i], y0 = nd$y[i], r = nd$r[i], start = starts, end = ends,
             fill = ifelse(names(v) == "Other", "Other", dim_name(names(v))))
    }) |> mutate(fill = factor(fill, levels = c(lab_lv, "Other")))
    p <- p +
      ggforce::geom_arc_bar(data = pie_df, aes(x0 = x0, y0 = y0, r0 = 0, r = r, start = start,
                                               end = end, fill = fill),
                            inherit.aes = FALSE, colour = "white", linewidth = 0.5) +
      ggforce::geom_circle(data = filter(nd, pie), aes(x0 = x, y0 = y, r = r), inherit.aes = FALSE,
                           fill = NA, colour = "white", linewidth = 0.6)
  }
  p <- p + scale_fill_manual(values = fills_all, breaks = lab_lv, name = "Dimension",
                             guide = guide_legend(order = 1, override.aes = list(alpha = 1, colour = NA)))
  
  if (any(nd$special))
    p <- p + ggforce::geom_circle(data = filter(nd, special),
                                  aes(x0 = x, y0 = y, r = r_out + 0.005), inherit.aes = FALSE,
                                  fill = NA, colour = gold, linewidth = 1.5)
  if (any(nd$halo))
    p <- p + ggforce::geom_circle(data = filter(nd, halo),
                                  aes(x0 = x, y0 = y, r = r_out + 0.010), inherit.aes = FALSE,
                                  fill = NA, colour = "grey20", linetype = "22", linewidth = 0.55)
  
  if (has_ring && isTRUE(PLOT_RING_VALUE_IN_NODE))
    p <- p + geom_text(data = filter(nd, !is.na(ring)),
                       aes(x = x, y = y, label = sprintf("%.0f", 100 * ring)),
                       inherit.aes = FALSE, size = 2.7, fontface = "bold", colour = "white")
  
  smart <- identical(PLOT_LABEL_MODE, "smart")
  p <- p +
    ggrepel::geom_text_repel(
      data = lab_df,
      aes(x = x, y = y, label = label, hjust = hj, vjust = vj,
          fontface = ff, colour = lab_col, point.size = ps),
      inherit.aes = FALSE, size = PLOT_LABEL_SIZE, lineheight = 0.88,
      bg.color = "white", bg.r = 0.12,
      force = if (smart) 0.2 else 0.6, force_pull = if (smart) 5 else 2,
      box.padding = if (smart) 0.05 else 0.12, point.padding = 0,
      min.segment.length = if (smart) Inf else 0.6,
      segment.colour = "grey65", segment.size = 0.25,
      max.overlaps = Inf, seed = PLOT_SEED) +
    scale_colour_identity()
  
  # ---- Inline key (ring / split fill / halo) ----
  # NOTE: every key layer uses ONE constant fill (vector fills break polygon geoms)
  kr <- PLOT_NODE_RADIUS; kx <- xr[1] + kr + 0.02
  cw <- 0.55 * 3 / mm_per_unit
  step_for <- function(txt) 2 * kr + 0.08 + max(nchar(strsplit(txt, "\n")[[1]])) * cw
  if (has_ring) {
    ring_lab <- if (PLOT_NODE_RING == "predictability")
      "Ring & number = predictability R\u00b2 (%):\nvariance explained by all other nodes"
    else "Ring & number = bootstrap item stability (%)"
    k0 <- tibble(x0 = kx, y0 = key_y)
    p <- p +
      ggforce::geom_arc_bar(data = k0, aes(x0 = x0, y0 = y0, r0 = kr, r = kr + rw, start = 0, end = 2 * pi),
                            inherit.aes = FALSE, fill = "grey88", colour = NA) +
      ggforce::geom_arc_bar(data = k0, aes(x0 = x0, y0 = y0, r0 = kr, r = kr + rw, start = 0, end = pi),
                            inherit.aes = FALSE, fill = "grey25", colour = NA) +
      ggforce::geom_circle(data = k0, aes(x0 = x0, y0 = y0, r = kr), inherit.aes = FALSE,
                           fill = "grey65", colour = "white") +
      annotate("text", x = kx, y = key_y, label = "50", size = 2.7, fontface = "bold", colour = "white") +
      annotate("text", x = kx + kr + rw + 0.02, y = key_y, label = ring_lab,
               hjust = 0, size = 3, colour = "grey25", lineheight = 0.9)
    kx <- kx + step_for(ring_lab)
  }
  if (any(nd$pie)) {
    pie_lab <- sprintf("Split fill = share of bootstrap replicates\nper dimension (bridge node, stability < %.2f)",
                       stab_threshold)
    kp <- tibble(x0 = kx, y0 = key_y)
    p <- p +
      ggforce::geom_arc_bar(data = kp, aes(x0 = x0, y0 = y0, r0 = 0, r = kr, start = 0, end = 0.6 * 2 * pi),
                            inherit.aes = FALSE, fill = "grey40", colour = "white", linewidth = 0.5) +
      ggforce::geom_arc_bar(data = kp, aes(x0 = x0, y0 = y0, r0 = 0, r = kr, start = 0.6 * 2 * pi, end = 2 * pi),
                            inherit.aes = FALSE, fill = "grey75", colour = "white", linewidth = 0.5) +
      annotate("text", x = kx + kr + 0.02, y = key_y, label = pie_lab,
               hjust = 0, size = 3, colour = "grey25", lineheight = 0.9)
    kx <- kx + step_for(pie_lab)
  }
  if (any(nd$halo)) {
    halo_lab <- sprintf("Dashed halo = item stability < %.2f\n(school-cluster bootstrap)", stab_threshold)
    kh <- tibble(x0 = kx, y0 = key_y)
    p <- p +
      ggforce::geom_circle(data = kh, aes(x0 = x0, y0 = y0, r = kr), inherit.aes = FALSE,
                           fill = "grey65", colour = "white") +
      ggforce::geom_circle(data = kh, aes(x0 = x0, y0 = y0, r = kr + rw + 0.010),
                           inherit.aes = FALSE, fill = NA, colour = "grey20",
                           linetype = "22", linewidth = 0.55) +
      annotate("text", x = kx + kr + rw + 0.03, y = key_y, label = halo_lab,
               hjust = 0, size = 3, colour = "grey25", lineheight = 0.9)
    kx <- kx + step_for(halo_lab)
  }
  
  p +
    expand_limits(x = c(xr[1], max(xr[2], kx)), y = c(key_y - kr - 0.03, yr[2])) +
    coord_equal(clip = "off") +
    labs(title = title_txt, subtitle = subtitle_txt, caption = caption_txt) +
    theme_void(base_size = 12) +
    theme(legend.position = "right", legend.box = "vertical",
          legend.title = element_text(face = "bold", size = 10.5),
          legend.text  = element_text(size = 9.5),
          legend.key.size = unit(0.9, "lines"),
          plot.title    = element_text(face = "bold", size = 15),
          plot.subtitle = element_text(size = 10, colour = "grey35", margin = margin(b = 8)),
          plot.caption  = element_text(size = 8.2, colour = "grey40", hjust = 0,
                                       lineheight = 1.1, margin = margin(t = 8)),
          plot.title.position = "plot", plot.caption.position = "plot",
          plot.margin = margin(14, 14, 10, 14))
}

# ============================================================
# ======================  1. LOAD DATA  ======================
# ============================================================
if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)
stamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

if (!file.exists(STU_DATA_FILE)) stop("STU data file not found: ", STU_DATA_FILE)
df <- readRDS(STU_DATA_FILE)
if (!file.exists(LOOKUP_FILE)) stop("Lookup file not found: ", LOOKUP_FILE)
lookup <- normalize_cntry_lookup(readRDS(LOOKUP_FILE))

vm <- if (file.exists(STU_VAR_FILE))
  tryCatch(read.csv(STU_VAR_FILE, stringsAsFactors = FALSE, check.names = FALSE),
           error = function(e) NULL) else NULL
if (is.null(vm)) vm <- build_variables_from_rds(df)
fc <- function(p) { for (pp in p) { m <- grep(pp, names(vm), ignore.case = TRUE, value = TRUE)
if (length(m)) return(m[1]) }; NA_character_ }
meta <- list(vm = vm,
             name     = fc(c("^Name$", "^Variable$", "^Var$")),
             vallabel = fc(c("Label.?Val", "Value.?Lab", "^Values$")),
             missing  = fc(c("Missing")))

constructs_df <- NULL
if (NET_SOURCE == "construct") {
  if (!file.exists(CONSTRUCTS_FILE)) stop(CONSTRUCTS_FILE, " not found.")
  constructs_df <- read.csv(CONSTRUCTS_FILE, stringsAsFactors = FALSE, check.names = FALSE)
}

# ============================================================
# ============  2. COUNTRY + DEMOGRAPHIC FILTERS  ============
# ============================================================
ids <- lookup |> filter(Country %in% FOCUS_COUNTRIES) |> pull(FCNT)
if (!length(ids)) stop("FOCUS_COUNTRIES not found in lookup.")
fd <- df |> filter(FCNT %in% ids)
for (vname in names(DEMO_FILTERS)) if (vname %in% names(fd))
  fd <- fd[as.character(as.vector(fd[[vname]])) %in% DEMO_FILTERS[[vname]], , drop = FALSE]
if (!nrow(fd)) stop("No students remain after filters.")
if (length(FOCUS_COUNTRIES) > 1)
  warning("Multiple countries: consider SENWT and country-specific strata.")
fd_plain <- haven::zap_labels(fd) |> as.data.frame()
cat("Students after filtering:", format(nrow(fd_plain), big.mark = ","), "\n")

rep_wts <- paste0(REP_WT_PREFIX, seq_len(N_REP))
miss_design <- setdiff(c(FINAL_WT, rep_wts, SCHOOL_ID, STRATUM_VAR), names(fd_plain))
if (length(miss_design))
  stop("Design variable(s) missing (analysis would be invalid): ",
       paste(head(miss_design, 8), collapse = ", "))
w_full <- as.numeric(fd_plain[[FINAL_WT]])

# ============================================================
# ================  3. BUILD NODE MATRICES  ==================
# ============================================================
node_cols <- list(); node_type <- character(0); comp_alpha <- c(); hard_log <- c()

if (NET_SOURCE == "construct") {
  for (k in SELECTED_CONSTRUCTS) {
    parts <- strsplit(k, "|||", fixed = TRUE)[[1]]
    act <- constructs_df[constructs_df$Group_ID == parts[1] & constructs_df$Assignment == parts[2], ]
    if (!nrow(act)) { warning("Construct ", k, " not found."); next }
    nm <- paste0(parts[1], "_", parts[2])
    res <- compute_construct(fd_plain, act, meta, w_full, CONSTRUCT_MIN_PROP)
    node_cols[[nm]] <- res$score; node_type[nm] <- "Construct"; comp_alpha[nm] <- res$alpha
  }
} else {
  for (k in SELECTED_INDICES) {
    if (!(k %in% names(fd_plain))) { warning("Index '", k, "' not found; skipped."); next }
    x <- clean_numeric(fd_plain[[k]], k, meta, "wle")
    hard_log[k] <- attr(x, "n_hard_removed")
    node_cols[[k]] <- as.numeric(x); node_type[k] <- "PISA index (WLE)"
  }
}
if (isTRUE(INCLUDE_EXTRA_NODES)) for (xn in names(EXTRA_NODES)) {
  en <- EXTRA_NODES[[xn]]
  rev <- if (length(en$reversed) == 1) rep(en$reversed, length(en$items)) else en$reversed
  present <- en$items %in% names(fd_plain)
  if (!all(present)) warning("Extra node ", xn, ": missing ", paste(en$items[!present], collapse = ", "))
  if (!any(present)) next
  mi <- min(en$min_items %||% length(en$items), sum(present))
  res <- compute_item_composite(fd_plain, en$items[present], rev[present],
                                en$max_scale, mi, meta, w_full)
  node_cols[[xn]] <- res$score; node_type[xn] <- "Item composite"; comp_alpha[xn] <- res$alpha
}
if (any(hard_log > 0)) { cat("Hard WLE safeguard removed values:\n"); print(hard_log[hard_log > 0]) }
var_names <- names(node_cols)
extra_names <- names(node_type)[node_type == "Item composite"]
if (length(var_names) < 2) stop("Need at least 2 non-PV nodes.")

# ---- Controls ----
if (any(ADJUST_FOR %in% var_names)) stop("A control variable is also a node.")
ctrl_cols <- list()
for (cv in ADJUST_FOR) {
  if (cv == "FEMALE") {
    g <- suppressWarnings(as.numeric(fd_plain$ST004D01D))
    ctrl_cols$FEMALE <- ifelse(g == 1, 1, ifelse(g == 2, 0, NA_real_))
  } else {
    if (!(cv %in% names(fd_plain))) stop("Control '", cv, "' not in data.")
    ctrl_cols[[cv]] <- as.numeric(clean_numeric(fd_plain[[cv]], cv, meta, "wle"))
  }
}
ctrl_names <- names(ctrl_cols); n_ctrl <- length(ctrl_names)

# ---- PVs ----
pv_list <- list()
for (d in SELECTED_DOMAINS) {
  pv_cols <- paste0("PV", seq_len(M_PV), d)
  if (!all(pv_cols %in% names(fd_plain))) { warning("PVs missing for ", d); next }
  pv_list[[d]] <- as.matrix(fd_plain[, pv_cols])
}
if (!length(pv_list)) stop("No PV columns available.")
pv_node_names <- paste0("PV_", names(pv_list))

# ============================================================
# ==========  4. ANALYSIS SAMPLE + ATTRITION  ================
# ============================================================
chk <- cbind(do.call(cbind, node_cols),
             if (n_ctrl) do.call(cbind, ctrl_cols),
             do.call(cbind, pv_list))
w0 <- ifelse(is.na(w_full), 0, w_full)
cc <- rowSums(is.na(chk)) == 0 & w0 > 0
if (sum(cc) < 100) stop("Analysis sample too small (", sum(cc), ").")

wmean <- function(x, w) { ok <- !is.na(x) & w > 0; sum(x[ok] * w[ok]) / sum(w[ok]) }
attrition_tab <- tibble(Variable = colnames(chk),
                        N_missing = colSums(is.na(chk)),
                        Pct_missing_weighted = round(100 * colSums(is.na(chk) * w0) / sum(w0), 2))
pv_mean_stu <- rowMeans(pv_list[[1]])
escs_raw <- if ("ESCS" %in% names(fd_plain)) as.numeric(clean_numeric(fd_plain$ESCS, "ESCS", meta, "wle")) else rep(NA_real_, nrow(fd_plain))
retention_tab <- tibble(
  Group = c("Analysis sample", "Excluded"),
  N = c(sum(cc), sum(!cc)),
  Weighted_share = round(c(sum(w0[cc]), sum(w0[!cc])) / sum(w0), 4),
  Mean_PV = round(c(wmean(pv_mean_stu[cc], w0[cc]), wmean(pv_mean_stu[!cc], w0[!cc])), 1),
  Mean_ESCS = round(c(wmean(escs_raw[cc], w0[cc]), wmean(escs_raw[!cc], w0[!cc])), 3))
cat("Analysis N (listwise):", sum(cc), "of", nrow(fd_plain), "\n"); print(retention_tab)

ia <- which(cc)
X_nodes <- as.matrix(as.data.frame(node_cols)[ia, , drop = FALSE]); colnames(X_nodes) <- var_names
CTRL    <- if (n_ctrl) { m0 <- as.matrix(as.data.frame(ctrl_cols)[ia, , drop = FALSE]); colnames(m0) <- ctrl_names; m0 } else NULL
pv_ana  <- lapply(pv_list, function(pm) pm[ia, , drop = FALSE])
W_all   <- as.matrix(fd_plain[ia, c(FINAL_WT, rep_wts)])
school_ana  <- as.character(fd_plain[[SCHOOL_ID]][ia])
stratum_ana <- as.character(fd_plain[[STRATUM_VAR]][ia])
n_analysis  <- length(ia)
n_kish      <- sum(W_all[, 1])^2 / sum(W_all[, 1]^2)

make_X <- function(m, rows = seq_len(n_analysis)) {
  pvm <- vapply(pv_ana, function(pm) pm[rows, m], numeric(length(rows)))
  pvm <- matrix(pvm, nrow = length(rows)); colnames(pvm) <- pv_node_names
  cbind(X_nodes[rows, , drop = FALSE], pvm, if (n_ctrl) CTRL[rows, , drop = FALSE])
}
set_idx <- function() {
  idx_n <<- seq_len(ncol(X_nodes) + length(pv_node_names))
  idx_c <<- if (n_ctrl) max(idx_n) + seq_len(n_ctrl) else integer(0)
}
set_idx()

# ============================================================
# ==========  5. UVA (optional; PV node protected)  ==========
# ============================================================
uva_result <- NULL
if (isTRUE(NET_USE_UVA) && length(var_names) >= 3) {
  Zpre <- lapply(seq_len(M_PV), function(m) fz(cond_cor(make_X(m), W_all[, 1], idx_n, idx_c)))
  R_pre <- tanh(Reduce(`+`, Zpre) / M_PV); diag(R_pre) <- 1
  R_uva <- R_pre[var_names, var_names]
  uva_raw <- tryCatch(call_safely(EGAnet::UVA,
                                  list(data = R_uva, n = n_analysis, uva.method = NET_UVA_METHOD,
                                       cut.off = NET_UVA_CUTOFF, reduce = TRUE, reduce.method = "remove",
                                       auto = TRUE, verbose = FALSE)),
                      error = function(e) { message("UVA error: ", conditionMessage(e)); NULL })
  if (!is.null(uva_raw)) {
    kept <- uva_raw$keep_remove$keep %||% colnames(uva_raw$reduced_data) %||% var_names
    kept <- intersect(var_names, kept); removed <- setdiff(var_names, kept)
    uva_result <- list(kept = kept, removed = removed, cutoff = NET_UVA_CUTOFF)
    if (length(removed) && length(kept) >= 2) {
      X_nodes <- X_nodes[, kept, drop = FALSE]; var_names <- kept
      extra_names <- intersect(extra_names, kept); set_idx()
      cat("UVA removed:", paste(removed, collapse = ", "), "\n")
    } else cat("UVA: no redundancy detected.\n")
  }
}
node_names <- c(var_names, pv_node_names)
p <- length(node_names); K <- p * (p - 1) / 2
ut <- upper.tri(diag(p)); pair_ij <- which(ut, arr.ind = TRUE)

# ============================================================
# ====  6. DESIGN-BASED ESTIMATION (10 PV x 81 weights)  =====
# ============================================================
cat("Design-based estimation: ", M_PV, " PVs x ", N_REP + 1, " weights...\n", sep = "")
Zr <- Zp <- array(NA_real_, dim = c(M_PV, N_REP + 1L, K))
Q2 <- array(NA_real_, dim = c(M_PV, N_REP + 1L, p))
for (m in seq_len(M_PV)) {
  X_m <- make_X(m)
  for (g in seq_len(N_REP + 1L)) {
    R_g  <- cond_cor(X_m, W_all[, g], idx_n, idx_c)
    Prec <- solve(R_g)
    Zr[m, g, ] <- fz(R_g[ut])
    Zp[m, g, ] <- fz((-stats::cov2cor(Prec))[ut])
    Q2[m, g, ] <- 1 - 1 / diag(Prec)
  }
}
pool_r <- pool_brr_rubin(Zr, FAY_K)
pool_p <- pool_brr_rubin(Zp, FAY_K)
pool_q <- pool_brr_rubin(Q2, FAY_K)
R_avg  <- vec_to_sym(tanh(pool_r$qbar), p, node_names)

# ============================================================
# ==================  7. EBIC SAMPLE SIZE  ===================
# ============================================================
deff_pairs <- pool_r$Ubar * (n_analysis - 3 - n_ctrl)
deff_med   <- stats::median(deff_pairs)
n_deff     <- n_analysis / deff_med
n_by_mode  <- c(nominal = n_analysis, kish = round(n_kish), deff = round(n_deff))
n_ebic     <- unname(n_by_mode[EBIC_N_MODE])
cat(sprintf("N analysis = %d | Kish n = %.0f | median DEFF(r) = %.2f -> n_deff = %.0f | EBIC n (%s) = %d\n",
            n_analysis, n_kish, deff_med, n_deff, EBIC_N_MODE, n_ebic))

ev_min <- min(eigen(R_avg, symmetric = TRUE, only.values = TRUE)$values)
pd_repaired <- ev_min < 1e-4
R_ega <- if (pd_repaired) repair_pd_correlation(R_avg) else R_avg
if (pd_repaired) cat("PD repair applied (min eigenvalue =", signif(ev_min, 4), ")\n")

# ============================================================
# =====================  8. MAIN EGA  ========================
# ============================================================
cat("Running EGA (", NET_MODEL, " + ", NET_ALGORITHM, ", seed ", EGA_SEED, ")...\n", sep = "")
ega_main <- tryCatch(run_ega(R_ega, n_ebic, NET_MODEL, NET_ALGORITHM, NET_UNI_METHOD, EGA_SEED),
                     error = function(e) stop("EGA failed: ", conditionMessage(e)))
wc_main <- setNames(get_wc(ega_main, node_names), node_names)
W_main  <- as.matrix(ega_main$network)
if (!is.null(rownames(W_main)) && all(node_names %in% rownames(W_main)))
  W_main <- W_main[node_names, node_names] else dimnames(W_main) <- list(node_names, node_names)
diag(W_main) <- 0
n_dim_main <- length(unique(wc_main[!is.na(wc_main)]))

if (!is.null(DIMENSION_LABELS) && !setequal(names(DIMENSION_LABELS), as.character(unique(na.omit(wc_main)))))
  warning("DIMENSION_LABELS keys do not match the communities found - check labels!")

nl <- tryCatch({ x <- EGAnet::net.loads(ega_main); x$std %||% x }, error = function(e) NULL)
netloads_df <- if (!is.null(nl)) tibble(Node = rownames(as.matrix(nl)), as_tibble(as.data.frame(as.matrix(nl)))) else NULL
tefi_val <- tefi_safe(R_ega, wc_main)

cat("\n========== EGA RESULT ==========\n")
cat("Nodes:", p, "| Dimensions:", n_dim_main, "| Non-zero edges:", sum(W_main[ut] != 0),
    "| TEFI:", round(tefi_val, 3), "\n")
print(tibble(Node = node_names, Community = wc_main, Dimension = dim_name(wc_main)), n = Inf)

# ============================================================
# ==================  9. SENSITIVITY GRID  ===================
# ============================================================
sens_tab <- NULL
if (isTRUE(RUN_SENSITIVITY)) {
  cat("\nSensitivity grid (EBIC n-mode x algorithm)...\n")
  sens_tab <- tidyr::expand_grid(n_mode = SENS_N_MODES, algorithm = SENS_ALGORITHMS) |>
    mutate(res = map2(n_mode, algorithm, function(nm, al) {
      e <- tryCatch(run_ega(R_ega, n_by_mode[[nm]], NET_MODEL, al, NET_UNI_METHOD, EGA_SEED),
                    error = function(err) NULL)
      if (is.null(e)) return(tibble(n_used = n_by_mode[[nm]], n_dim = NA_integer_,
                                    n_edges = NA_integer_, ARI_vs_main = NA_real_,
                                    TEFI = NA_real_, membership = NA_character_))
      wc <- get_wc(e, node_names)
      tibble(n_used = n_by_mode[[nm]], n_dim = length(unique(na.omit(wc))),
             n_edges = sum(as.matrix(e$network)[ut] != 0),
             ARI_vs_main = round(ari_safe(wc, wc_main), 3),
             TEFI = round(tefi_safe(R_ega, wc), 3),
             membership = paste(node_names, wc, sep = "=", collapse = "; "))
    })) |> unnest(res)
  print(sens_tab |> select(-membership), n = Inf)
  best_tefi <- sens_tab |> filter(n_mode == EBIC_N_MODE, !is.na(TEFI)) |>
    slice_min(TEFI, n = 1, with_ties = FALSE)
  if (nrow(best_tefi))
    cat(sprintf("Lowest TEFI (%s n): %s (TEFI = %.3f; main = %s)\n",
                EBIC_N_MODE, best_tefi$algorithm, best_tefi$TEFI, NET_ALGORITHM))
}

# ============================================================
# ================  10. STABILITY (bootstrap)  ===============
# ============================================================
boot_cluster <- boot_param <- NULL
W_boot <- S_boot <- NULL
iter_n <- as.integer(min(max(NET_BOOT_ITER, 50), 5000))

if (isTRUE(RUN_BOOTEGA) && BOOT_TYPE %in% c("cluster", "both")) {
  cat("\nSchool-cluster bootstrap within strata (B =", iter_n, ")...\n")
  rows_by_school <- split(seq_len(n_analysis), school_ana)
  sch_str <- vapply(rows_by_school, function(r) stratum_ana[r[1]], character(1))
  sch_by_str <- split(names(rows_by_school), sch_str)
  n_single <- sum(lengths(sch_by_str) == 1)
  if (n_single) cat("  Note:", n_single, "stratum/strata with a single school (no between-school variation).\n")
  set.seed(NET_BOOT_SEED)
  wc_boot <- matrix(NA_integer_, iter_n, p, dimnames = list(NULL, node_names))
  W_boot  <- matrix(NA_real_, iter_n, K)
  S_boot  <- matrix(NA_real_, iter_n, p, dimnames = list(NULL, node_names))
  for (b in seq_len(iter_n)) {
    sch_b <- unlist(lapply(sch_by_str, function(s) s[sample.int(length(s), length(s), replace = TRUE)]),
                    use.names = FALSE)
    rows <- unlist(rows_by_school[sch_b], use.names = FALSE)
    m <- ((b - 1L) %% M_PV) + 1L
    R_b <- tryCatch(cond_cor(make_X(m, rows), W_all[rows, 1], idx_n, idx_c), error = function(e) NULL)
    if (is.null(R_b)) next
    e_b <- tryCatch(run_ega(R_b, n_ebic, NET_MODEL, NET_ALGORITHM, NET_UNI_METHOD, seed = NULL),
                    error = function(e) NULL)
    if (is.null(e_b)) next
    Wb <- as.matrix(e_b$network); diag(Wb) <- 0
    wc_boot[b, ] <- get_wc(e_b, node_names)
    W_boot[b, ]  <- Wb[ut]
    S_boot[b, ]  <- rowSums(abs(Wb))
    if (b %% 50 == 0) cat("  replicate", b, "/", iter_n, "\n")
  }
  boot_cluster <- summarise_stability(wc_boot, wc_main, node_names,
                                      "School-cluster bootstrap within strata")
}

if (isTRUE(RUN_BOOTEGA) && BOOT_TYPE %in% c("parametric", "both")) {
  cat("\nNative parametric bootEGA (comparison; ignores design)...\n")
  bt <- tryCatch(call_safely(EGAnet::bootEGA,
                             list(data = R_ega, n = n_ebic, iter = iter_n, type = "parametric",
                                  model = NET_MODEL, algorithm = NET_ALGORITHM,
                                  uni.method = NET_UNI_METHOD, seed = NET_BOOT_SEED,
                                  typicalStructure = FALSE, plot.typicalStructure = FALSE,
                                  plot.itemStability = FALSE, ncores = 1,
                                  verbose = FALSE, clear = TRUE, suppress = TRUE),
                             if (identical(NET_ALGORITHM, "leiden")) LEIDEN_ARGS else list()),
                 error = function(e) { message("bootEGA error: ", conditionMessage(e)); NULL })
  if (!is.null(bt) && !is.null(bt$boot.wc)) {
    bw <- bt$boot.wc
    if (is.list(bw) && !is.matrix(bw)) bw <- do.call(rbind, bw)
    bw <- as.matrix(bw)
    if (!is.null(colnames(bw)) && all(node_names %in% colnames(bw))) bw <- bw[, node_names]
    boot_param <- summarise_stability(bw, wc_main, node_names, "Parametric bootEGA (i.i.d.)")
  }
}
boot_main <- boot_cluster %||% boot_param

if (!is.null(boot_main)) {
  cat("\n========== STABILITY (", boot_main$source, ") ==========\n", sep = "")
  cat("Usable replicates:", boot_main$n_used,
      "| Same n.dim as empirical:", round(100 * mean(boot_main$ndim == n_dim_main), 1), "%",
      "| Median ARI:", round(stats::median(boot_main$ari, na.rm = TRUE), 3), "\n")
  print(boot_main$dim, width = Inf)
  print(boot_main$item, n = Inf, width = Inf)
  br_tab <- boot_main$item |> filter(Bridge)
  if (nrow(br_tab)) {
    cat("\nBridge nodes (item stability <", ITEM_STAB_THRESHOLD, "):\n")
    print(br_tab |> select(Node, Community, Item_Stability, Modal_Community, Modal_Prop,
                           Alt_Community, Alt_Prop, Modal_differs), width = Inf)
  }
}

# ============================================================
# ================  11. PUBLICATION TABLES  ==================
# ============================================================
edge_tab <- tibble(
  From = node_names[pair_ij[, 1]], To = node_names[pair_ij[, 2]],
  glasso_weight = W_main[ut],
  in_EGA_network = abs(W_main[ut]) > 1e-8,
  r_adj    = tanh(pool_r$qbar),
  r_lo     = tanh(pool_r$qbar - Z_CRIT * sqrt(pool_r$T)),
  r_hi     = tanh(pool_r$qbar + Z_CRIT * sqrt(pool_r$T)),
  pcor     = tanh(pool_p$qbar),
  pcor_se  = (1 - tanh(pool_p$qbar)^2) * sqrt(pool_p$T),
  pcor_lo  = tanh(pool_p$qbar - Z_CRIT * sqrt(pool_p$T)),
  pcor_hi  = tanh(pool_p$qbar + Z_CRIT * sqrt(pool_p$T)),
  pcor_p   = 2 * stats::pnorm(-abs(pool_p$qbar / sqrt(pool_p$T))),
  pcor_fmi = pool_p$fmi
) |> mutate(pcor_q = stats::p.adjust(pcor_p, "BH"))

if (!is.null(W_boot) && any(!is.na(W_boot[, 1]))) {
  okb <- !is.na(W_boot[, 1])
  edge_tab <- edge_tab |> mutate(
    boot_inclusion = colMeans(abs(W_boot[okb, , drop = FALSE]) > 1e-8),
    boot_w_lo = apply(W_boot[okb, , drop = FALSE], 2, stats::quantile, 0.025),
    boot_w_hi = apply(W_boot[okb, , drop = FALSE], 2, stats::quantile, 0.975))
} else edge_tab <- edge_tab |> mutate(boot_inclusion = NA_real_, boot_w_lo = NA_real_, boot_w_hi = NA_real_)
edge_tab <- edge_tab |> mutate(From_label = flat_label(From), To_label = flat_label(To), .after = To) |>
  arrange(desc(abs(glasso_weight)))

type_vec <- ifelse(node_names %in% pv_node_names, "Achievement (PV)", node_type[node_names])
strength_v <- rowSums(abs(W_main)); ei_v <- rowSums(W_main)
dims_df <- tibble(Node = node_names, Label = flat_label(node_names), Type = unname(type_vec),
                  Community = wc_main, Dimension = dim_name(wc_main),
                  Strength = strength_v, Expected_Influence = ei_v)
if (!is.null(S_boot) && any(!is.na(S_boot[, 1]))) {
  okb <- !is.na(S_boot[, 1])
  dims_df <- dims_df |> mutate(
    Strength_boot_lo = apply(S_boot[okb, , drop = FALSE], 2, stats::quantile, 0.025),
    Strength_boot_hi = apply(S_boot[okb, , drop = FALSE], 2, stats::quantile, 0.975))
}
if (!is.null(boot_main))
  dims_df <- dims_df |> left_join(boot_main$item |>
                                    select(Node, Item_Stability, Modal_Community, Modal_Prop,
                                           Modal_differs, Bridge),
                                  by = "Node")

pred_tab <- tibble(
  Node = node_names, Label = flat_label(node_names),
  Predictability_R2 = pool_q$qbar,
  R2_se  = sqrt(pool_q$T),
  R2_lo  = pmax(0, pool_q$qbar - Z_CRIT * sqrt(pool_q$T)),
  R2_hi  = pmin(1, pool_q$qbar + Z_CRIT * sqrt(pool_q$T)),
  R2_fmi = pool_q$fmi)
dims_df <- dims_df |> left_join(select(pred_tab, Node, Predictability_R2), by = "Node") |>
  arrange(Community, desc(Strength))
cat("\n========== NODE PREDICTABILITY (R2, design-based) ==========\n")
print(pred_tab |> arrange(desc(Predictability_R2)) |>
        mutate(across(where(is.numeric), \(z) round(z, 3))), n = Inf)

desc_tab <- tibble(
  Node = node_names, Label = flat_label(node_names), Type = unname(type_vec),
  Weighted_mean = vapply(node_names, function(v) if (v %in% pv_node_names)
    mean(apply(pv_ana[[sub("^PV_", "", v)]], 2, wmean, w = W_all[, 1])) else wmean(X_nodes[, v], W_all[, 1]), numeric(1)),
  Weighted_SD = vapply(node_names, function(v) {
    x <- if (v %in% pv_node_names) pv_ana[[sub("^PV_", "", v)]][, 1] else X_nodes[, v]
    sqrt(stats::cov.wt(matrix(x), wt = W_all[, 1] / sum(W_all[, 1]))$cov[1]) }, numeric(1)),
  Alpha_weighted = unname(comp_alpha[node_names]))

# ---- Write CSVs ----
wcsv <- function(x, stub) if (!is.null(x))
  write.csv(x, file.path(OUTPUT_DIR, paste0(stub, "_", stamp, ".csv")), row.names = FALSE)
wcsv(edge_tab, "Table_edges_design_based")
wcsv(dims_df, "Table_nodes_dimensions_centrality")
wcsv(pred_tab, "Table_node_predictability")
wcsv(desc_tab, "Table_node_descriptives")
wcsv(attrition_tab, "Table_attrition_by_variable")
wcsv(retention_tab, "Table_retained_vs_excluded")
wcsv(netloads_df, "Table_network_loadings")
wcsv(sens_tab, "Table_sensitivity_n_algorithm")
wcsv(cbind(Node = node_names, as.data.frame(R_avg)), "Matrix_pooled_adjusted_correlation")
wcsv(cbind(Node = node_names, as.data.frame(W_main)), "Matrix_EGA_network")
for (bs in list(boot_cluster, boot_param)) if (!is.null(bs)) {
  tag <- if (!is.null(boot_cluster) && identical(bs$source, boot_cluster$source)) "cluster" else "parametric"
  wcsv(bs$item, paste0("Table_item_stability_", tag))
  wcsv(bs$dim,  paste0("Table_dimension_stability_", tag))
  wcsv(tibble(n_dim = bs$ndim) |> count(n_dim) |> mutate(prop = n / sum(n)),
       paste0("Table_ndim_frequency_", tag))
  wcsv(cbind(Node = node_names, as.data.frame(bs$coassign)), paste0("Matrix_coassignment_", tag))
  mp <- as.data.frame(bs$memb_prop)
  names(mp) <- ifelse(names(mp) == "Other", "Other", paste0("Dim_", names(mp)))
  wcsv(cbind(Node = node_names, Label = flat_label(node_names), mp),
       paste0("Table_bootstrap_membership_", tag))
}
if (!is.null(uva_result)) wcsv(tibble(Kept = paste(uva_result$kept, collapse = ", "),
                                      Removed = paste(uva_result$removed, collapse = ", "),
                                      Cutoff = uva_result$cutoff), "Table_UVA")

# ============================================================
# ======================  12. FIGURES  =======================
# ============================================================
if (isTRUE(SAVE_PLOT)) {
  # re-run starts for plot graph with new layout
  edges_plot <- edge_tab |> filter(in_EGA_network) |>
    transmute(From, To, Weight = glasso_weight, pcor_q, boot_inclusion)
  aw <- abs(edges_plot$Weight)
  bb_flag <- switch(PLOT_BACKBONE_RULE,
                    topn        = aw >= sort(aw, decreasing = TRUE)[min(PLOT_BACKBONE_TOPN, length(aw))],
                    significant = edges_plot$pcor_q < FDR_ALPHA,
                    stable      = edges_plot$boot_inclusion >= PLOT_STABLE_MIN,
                    sig_stable  = edges_plot$pcor_q < FDR_ALPHA & edges_plot$boot_inclusion >= PLOT_STABLE_MIN,
                    aw >= PLOT_BACKBONE_MIN)
  bb_flag <- bb_flag %in% TRUE
  if (isTRUE(PLOT_HIGHLIGHT_PV_EDGES))
    bb_flag <- bb_flag | edges_plot$From %in% pv_node_names | edges_plot$To %in% pv_node_names
  bb_txt <- switch(PLOT_BACKBONE_RULE,
                   topn        = paste0(PLOT_BACKBONE_TOPN, " strongest edges"),
                   significant = paste0("design-based FDR q < ", FDR_ALPHA),
                   stable      = paste0("bootstrap inclusion \u2265 ", PLOT_STABLE_MIN),
                   sig_stable  = paste0("FDR q < ", FDR_ALPHA, " & bootstrap inclusion \u2265 ", PLOT_STABLE_MIN),
                   paste0("|weight| \u2265 ", PLOT_BACKBONE_MIN))
  
  item_stab_vec <- if (!is.null(boot_main))
    setNames(boot_main$item$Item_Stability, boot_main$item$Node) else NULL
  pred_vec   <- setNames(pool_q$qbar, node_names)
  n_unstable <- if (!is.null(item_stab_vec)) sum(item_stab_vec < ITEM_STAB_THRESHOLD, na.rm = TRUE) else 0
  
  net_title <- if (PLOT_SHOW_TITLE) sprintf("Student agency and Science performance: %s (N = %s)",
                                            paste(FOCUS_COUNTRIES, collapse = ", "),
                                            format(n_analysis, big.mark = ",")) else NULL
  net_sub <- if (PLOT_SHOW_TITLE)
    paste0("Exploratory Graph Analysis",
           if (n_ctrl) paste0(", adjusted for ", paste(ctrl_names, collapse = ", ")) else ", unadjusted") else NULL
  
  hull_txt <- switch(PLOT_HULL_MEMBERS,
                     core  = "Shaded regions: EGA dimensions drawn on core (stable) nodes only",
                     modal = "Shaded regions: modal bootstrap dimension of each node",
                     "Shaded regions: EGA dimensions")
  bridge_txt <- if (n_unstable > 0) {
    parts <- c(
      if (PLOT_BRIDGE_STYLE %in% c("pie", "both"))
        "split fill = share of bootstrap replicates assigning the node to each dimension",
      if (PLOT_BRIDGE_STYLE %in% c("halo", "both")) "dashed halo")
    if (length(parts)) sprintf("Bridge nodes (item stability < %.2f): %s.", ITEM_STAB_THRESHOLD,
                               paste(parts, collapse = "; ")) else NULL
  } else NULL
  
  net_cap <- wrap_caption(c(
    paste0("Edges: EBICglasso partial correlations (EBIC n = ", format(n_ebic, big.mark = ","), ", ",
           EBIC_N_MODE, ") from W_FSTUWT-weighted correlations pooled over 10 PVs (Fisher z). ",
           "Width \u221d |weight| on one common scale; coloured = backbone (", bb_txt,
           if (isTRUE(PLOT_HIGHLIGHT_PV_EDGES)) " or incident to achievement", "), grey = weaker edges."),
    switch(PLOT_NODE_RING,
           predictability = paste0("Ring & number: node predictability R\u00b2 (%) from the unregularised ",
                                   if (n_ctrl) "adjusted " else "", "correlation matrix, design-based (Fay-BRR \u00d7 Rubin)."),
           item_stability = "Ring & number: bootstrap item stability (%).", NULL),
    switch(PLOT_NODE_SIZE_BY, item_stability = "Node area \u221d item stability.",
           predictability = "Node area \u221d predictability.", strength = "Node area \u221d strength.", NULL),
    bridge_txt,
    paste0(hull_txt, " (", NET_ALGORITHM, ", seed ", EGA_SEED, ")",
           if (!is.null(boot_main)) sprintf("; median bootstrap ARI = %.2f (B = %d)",
                                            stats::median(boot_main$ari, na.rm = TRUE), boot_main$n_used),
           ". Gold ring = science achievement.")))
  
  pg <- NULL
  if (identical(PLOT_ENGINE, "ggraph"))
    pg <- tryCatch(plot_ega_network(
      edges_in = edges_plot, node_names = node_names, comm_vec = wc_main,
      backbone_flag = bb_flag, pred = pred_vec, item_stab = item_stab_vec,
      strength = setNames(strength_v, node_names),
      memb_prop = if (!is.null(boot_main)) boot_main$memb_prop else NULL,
      coassign  = if (!is.null(boot_main)) boot_main$coassign  else NULL,
      special_nodes = pv_node_names, stab_threshold = ITEM_STAB_THRESHOLD,
      title_txt = net_title, subtitle_txt = net_sub, caption_txt = net_cap),
      error = function(e) { message("Network plot construction error: ", conditionMessage(e)); NULL })
  
  # ggplot errors are lazy -> fully render off-screen before accepting the plot
  if (!is.null(pg)) {
    ok <- tryCatch(check_renderable(pg), error = function(e) {
      message("Network plot render error: ", conditionMessage(e)); FALSE })
    if (!isTRUE(ok)) pg <- NULL
  }
  if (is.null(pg)) {
    message("Falling back to the EGAnet default network plot.")
    pg <- tryCatch(plot(ega_main), error = function(e) NULL)
  }
  save_plot(pg, "Fig1_EGA_network", PLOT_WIDTH, PLOT_HEIGHT)
  # re-run ends for plot graph with new layout
  
  save_plot(plot_pv_forest(edge_tab, pv_node_names,
                           "Design-based partial correlations with science achievement"),
            "Fig2_PV_edges_forest", 8, 6)
  if (!is.null(boot_main)) {
    save_plot(plot_item_stability(boot_main$item, ITEM_STAB_THRESHOLD,
                                  paste0("Item stability | ", boot_main$source)),
              "Fig3_item_stability", 10, 7)
    save_plot(plot_dimension_stability(boot_main$dim,
                                       paste0("Dimension stability | ", boot_main$source)),
              "Fig4_dimension_stability", 8, 5.5)
    save_plot(plot_ndim(boot_main$ndim, n_dim_main, "Bootstrap distribution of dimensions"),
              "Fig5_ndim_frequency", 6, 4.5)
    save_plot(plot_coassign(boot_main$coassign, wc_main, "Bootstrap co-assignment"),
              "FigS1_coassignment", 10, 9)
  }
}

# ============================================================
# ==========  13. RESULT OBJECT + METHODS SUMMARY  ===========
# ============================================================
net_result <- list(
  ega = ega_main, wc = wc_main, W = W_main, R_pooled = R_avg, R_used = R_ega,
  edge_table = edge_tab, nodes = dims_df, descriptives = desc_tab,
  predictability = pred_tab,
  pooling = list(r = pool_r, pcor = pool_p, r2 = pool_q),
  n = list(analysis = n_analysis, kish = n_kish, deff_median = deff_med,
           n_deff = n_deff, ebic = n_ebic, mode = EBIC_N_MODE),
  sensitivity = sens_tab, boot_cluster = boot_cluster, boot_parametric = boot_param,
  net_loads = netloads_df, tefi = tefi_val, uva = uva_result, controls = ctrl_names,
  attrition = attrition_tab, retention = retention_tab, pd_repaired = pd_repaired,
  config = mget(ls(pattern = "^(NET_|EBIC_|ADJUST_|FAY_|N_REP|BOOT_|EGA_SEED|SELECTED_|EXTRA_NODES|PLOT_|ITEM_STAB)")))
saveRDS(net_result, file.path(OUTPUT_DIR, paste0("EGA_network_result_", stamp, ".rds")))

pv_sig  <- edge_tab |> filter((From %in% pv_node_names | To %in% pv_node_names) & pcor_q < FDR_ALPHA)
pred_pv <- pred_tab |> filter(Node %in% pv_node_names)
tefi_line <- if (!is.null(sens_tab) && any(!is.na(sens_tab$TEFI))) {
  bt0 <- sens_tab |> filter(n_mode == EBIC_N_MODE, !is.na(TEFI)) |> slice_min(TEFI, n = 1, with_ties = FALSE)
  if (nrow(bt0)) sprintf("Sensitivity: lowest TEFI among algorithms (%s n) = %s (%.3f; ARI vs main = %.2f); main algorithm = %s.",
                         EBIC_N_MODE, bt0$algorithm, bt0$TEFI, bt0$ARI_vs_main, NET_ALGORITHM) else NULL
} else NULL

bridge_lines <- NULL; core_line <- NULL
if (!is.null(boot_main)) {
  br <- boot_main$item |> filter(Bridge)
  if (nrow(br)) bridge_lines <- c(
    sprintf("Bridge nodes (item stability < %.2f): %d", ITEM_STAB_THRESHOLD, nrow(br)),
    sprintf("  %s: assigned Dim %s (stability = %.2f); modal = %s (%.0f%%); runner-up = %s (%.0f%%)%s",
            br$Node, br$Community, br$Item_Stability,
            dim_short(br$Modal_Community), 100 * br$Modal_Prop,
            dim_short(br$Alt_Community), 100 * br$Alt_Prop,
            ifelse(br$Modal_differs, "  [modal differs from assigned]", "")))
  core_line <- paste0("Structural consistency, all items / core items: ",
                      paste(sprintf("Dim %s = %.2f / %.2f", boot_main$dim$Dimension,
                                    boot_main$dim$Structural_Consistency,
                                    boot_main$dim$Core_Consistency), collapse = "; "), ".")
}

methods_txt <- c(
  "=== METHODS / RESULTS SUMMARY (auto-generated) ===",
  sprintf("Country: %s | Analysis N (listwise) = %d of %d (weighted share retained = %.1f%%)",
          paste(FOCUS_COUNTRIES, collapse = ", "), n_analysis, nrow(fd_plain), 100 * retention_tab$Weighted_share[1]),
  sprintf("Nodes: %d (%s) | Adjusted for: %s", p, paste(node_names, collapse = ", "),
          if (n_ctrl) paste(ctrl_names, collapse = ", ") else "none"),
  sprintf("Weights: %s; variance: Fay-BRR (%d replicates, k = %.1f) combined with Rubin's rules over %d PVs (Fisher-z scale).",
          FINAL_WT, N_REP, FAY_K, M_PV),
  sprintf("EBIC n = %d (%s); Kish n = %.0f; median DEFF(r) = %.2f; n/DEFF = %.0f.",
          n_ebic, EBIC_N_MODE, n_kish, deff_med, n_deff),
  sprintf("EGA: %s + %s (seed %d); dimensions = %d; non-zero edges = %d of %d; TEFI = %.3f%s.",
          NET_MODEL, NET_ALGORITHM, EGA_SEED, n_dim_main, sum(W_main[ut] != 0), K, tefi_val,
          if (pd_repaired) "; PD repair applied" else ""),
  tefi_line,
  if (!is.null(boot_main)) sprintf("Stability (%s, B = %d): empirical n.dim recovered in %.1f%%; median ARI = %.3f; mean item stability = %.3f.",
                                   boot_main$source, boot_main$n_used, 100 * mean(boot_main$ndim == n_dim_main),
                                   stats::median(boot_main$ari, na.rm = TRUE),
                                   mean(boot_main$item$Item_Stability, na.rm = TRUE)),
  core_line,
  bridge_lines,
  sprintf("Node predictability (R2, unregularised, design-based%s): mean = %.3f; range = %.3f-%.3f.",
          if (n_ctrl) paste0(", beyond ", paste(ctrl_names, collapse = ", ")) else "",
          mean(pred_tab$Predictability_R2), min(pred_tab$Predictability_R2), max(pred_tab$Predictability_R2)),
  if (nrow(pred_pv)) paste0("  ", pred_pv$Node, ": R2 = ", sprintf("%.3f", pred_pv$Predictability_R2),
                            " [", sprintf("%.3f", pred_pv$R2_lo), ", ", sprintf("%.3f", pred_pv$R2_hi), "]"),
  sprintf("Achievement edges with FDR q < %.2f: %d", FDR_ALPHA, nrow(pv_sig)),
  if (nrow(pv_sig)) paste0("  ", pv_sig$From, " - ", pv_sig$To, ": pcor = ", sprintf("%.3f", pv_sig$pcor),
                           " [", sprintf("%.3f", pv_sig$pcor_lo), ", ", sprintf("%.3f", pv_sig$pcor_hi), "]"),
  sprintf("Packages: EGAnet %s, igraph %s, R %s", utils::packageVersion("EGAnet"),
          utils::packageVersion("igraph"), getRversion()))
writeLines(methods_txt, file.path(OUTPUT_DIR, paste0("Methods_summary_", stamp, ".txt")))
writeLines(capture.output(sessionInfo()), file.path(OUTPUT_DIR, paste0("sessionInfo_", stamp, ".txt")))
cat("\n", paste(methods_txt, collapse = "\n"), "\n")
cat("\nDONE. Outputs saved to: ", normalizePath(OUTPUT_DIR), "\n", sep = "")
